# -*- coding: utf-8 -*-
"""
Resolves organizational unit names to hierarchical codes.
Parses Arabic unit names like "وحدة توزيع 1 - إربد" into structured components.
"""
import re
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.organization import OrganizationUnit


class OrgUnitResolver:
    """
    Maps Arabic unit names → {type, province_code, directorate_code, section_num, unit_num, full_code}
    """

    PROVINCES = {
        "إربد": ("IRB", "Irbid"),
        "عجلون": ("AJL", "Ajloun"),
        "جرش": ("JER", "Jerash"),
        "المفرق": ("MAF", "Mafraq"),
        "الزرقاء": ("ZAR", "Zarqa"),
        "العاصمة": ("AMM", "Amman"),
        "البلقاء": ("BAL", "Balqa"),
        "الكرك": ("KAR", "Karak"),
        "معان": ("MAN", "Maan"),
        "الطفيلة": ("TAF", "Tafila"),
        "مادبا": ("MAD", "Madaba"),
        "العقبة": ("AQB", "Aqaba"),
    }

    DIRECTORATES = {
        "توزيع المياه": "WAT",
        "توزيع": "WAT",
        "الصرف الصحي": "SAN",
        "صرف صحي": "SAN",
        "صرف": "SAN",
        "خدمات المشتركين": "CUS",
        "خدمات": "CUS",
        "الصيانة": "MNT",
        "صيانة": "MNT",
        "المستودعات": "DEP",
        "مستودع": "DEP",
        "المالية": "FIN",
        "مالية": "FIN",
        "الديوان": "DIV",
        "ديوان": "DIV",
        "الموارد البشرية": "HR",
        "تقنية المعلومات": "IT",
    }

    @staticmethod
    def detect_province(text: str) -> Optional[str]:
        for name_ar, (code, _) in OrgUnitResolver.PROVINCES.items():
            if name_ar in text:
                return code
        return None

    @staticmethod
    def detect_directorate(text: str) -> Optional[str]:
        for keyword, code in OrgUnitResolver.DIRECTORATES.items():
            if keyword in text:
                return code
        return None

    @staticmethod
    def detect_unit_type(text: str) -> str:
        if "محافظة" in text:
            return "PROVINCE"
        if "مديرية" in text:
            return "DIRECTORATE"
        if "قسم" in text:
            return "SECTION"
        if "وحدة" in text:
            return "UNIT"
        if "شعبة" in text:
            return "SUBSECTION"
        if "مستودع" in text:
            return "DEPOT"
        if text.startswith("الشركة") or "مركز رئيسي" in text or "الرئيسي" in text:
            return "COMPANY"
        return "UNIT"

    @staticmethod
    def extract_number(text: str, prefix: str = "") -> Optional[int]:
        m = re.search(rf"{re.escape(prefix)}\s*(\d+)", text)
        if m:
            return int(m.group(1))
        m = re.search(r"(\d+)", text)
        if m:
            return int(m.group(1))
        return None

    def parse(self, org_name: str) -> dict:
        name = str(org_name or "").strip()
        if not name:
            return {}

        unit_type = self.detect_unit_type(name)
        province_code = self.detect_province(name)
        directorate_code = self.detect_directorate(name)
        section_num = self.extract_number(name)
        unit_num = self.extract_number(name) if unit_type == "UNIT" else None

        return {
            "name": name,
            "type": unit_type,
            "province_code": province_code,
            "directorate_code": directorate_code,
            "section_num": section_num,
            "unit_num": unit_num,
        }

    def build_code(self, parsed: dict) -> str:
        t = parsed.get("type", "UNIT")
        province = parsed.get("province_code", "X")
        directorate = parsed.get("directorate_code", "X")
        section_num = parsed.get("section_num")
        unit_num = parsed.get("unit_num")

        prefix_map = {
            "COMPANY": "COMP",
            "PROVINCE": "PROV",
            "DIRECTORATE": "DIR",
            "SECTION": "SEC",
            "SUBSECTION": "SUB",
            "UNIT": "UNT",
            "DEPOT": "DEP",
            "FINANCE": "FIN",
            "DIWAN": "DIV",
        }
        prefix = prefix_map.get(t, "UNT")

        if t == "COMPANY":
            return f"{prefix}"
        if t == "PROVINCE":
            return f"{prefix}-{province}"
        if t == "DIRECTORATE":
            return f"{prefix}-{province}-{directorate}"
        if t == "SECTION":
            sn = f"{section_num:02d}" if section_num else "01"
            return f"{prefix}-{province}-{directorate}-{sn}"
        if t == "UNIT":
            sn = f"{section_num:02d}" if section_num else "01"
            un = f"{unit_num}" if unit_num else "1"
            return f"{prefix}-{province}-{directorate}-{sn}-{un}"
        return f"{prefix}-{province}-{directorate}"

    async def get_or_create(self, db: AsyncSession, parsed: dict) -> int:
        unit_type = parsed["type"]
        name = parsed["name"]

        res = await db.execute(
            select(OrganizationUnit.org_unit_id).where(OrganizationUnit.unit_name == name)
        )
        existing = res.scalar_one_or_none()
        if existing:
            return existing

        parent_id = None
        province_code = parsed.get("province_code")
        directorate_code = parsed.get("directorate_code")

        if province_code and unit_type in ("DIRECTORATE", "SECTION", "UNIT", "SUBSECTION", "DEPOT", "FINANCE", "DIWAN"):
            province_name = next(
                (n for n, c in self.PROVINCES.items() if c[0] == province_code),
                None,
            )
            if province_name:
                prov_res = await db.execute(
                    select(OrganizationUnit.org_unit_id).where(
                        OrganizationUnit.unit_name == f"محافظة {province_name}"
                    )
                )
                prov_id = prov_res.scalar_one_or_none()
                if prov_id is None:
                    prov = OrganizationUnit(
                        unit_name=f"محافظة {province_name}",
                        unit_type="PROVINCE",
                        is_active=True,
                    )
                    db.add(prov)
                    await db.flush()
                    prov_id = prov.org_unit_id
                parent_id = prov_id

                if directorate_code and unit_type in ("SECTION", "UNIT", "SUBSECTION"):
                    directorate_name = next(
                        (k for k, c in self.DIRECTORATES.items() if c == directorate_code),
                        None,
                    )
                    if directorate_name:
                        dir_full = f"مديرية {directorate_name} - {province_name}"
                        dir_res = await db.execute(
                            select(OrganizationUnit.org_unit_id).where(OrganizationUnit.unit_name == dir_full)
                        )
                        dir_id = dir_res.scalar_one_or_none()
                        if dir_id is None:
                            dir_unit = OrganizationUnit(
                                unit_name=dir_full,
                                unit_type="DIRECTORATE",
                                is_active=True,
                                parent_id=parent_id,
                            )
                            db.add(dir_unit)
                            await db.flush()
                            dir_id = dir_unit.org_unit_id
                        parent_id = dir_id

        new_unit = OrganizationUnit(
            unit_name=name,
            unit_type=unit_type,
            is_active=True,
            parent_id=parent_id,
        )
        db.add(new_unit)
        await db.flush()
        return new_unit.org_unit_id


org_resolver = OrgUnitResolver()
