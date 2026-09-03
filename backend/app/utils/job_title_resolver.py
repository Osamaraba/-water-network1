# -*- coding: utf-8 -*-
"""
Resolves job titles + directorate → full title + code.
Example: ("WAT", "مدير") → ("WAT-MGR", "مدير مديرية توزيع المياه")
"""
from typing import Optional


class JobTitleResolver:
    TITLES_BY_DIRECTORATE = {
        "WAT": {
            "مدير":          ("WAT-MGR",      "مدير مديرية توزيع المياه"),
            "رئيس قسم":      ("WAT-SEC-HEAD", "رئيس قسم توزيع المياه"),
            "فني":           ("WAT-TECH",     "فني توزيع مياه"),
            "مراقب":         ("WAT-SUP",      "مراقب توزيع"),
            "قارئ عدادات":   ("WAT-MTR-RD",   "قارئ عدادات"),
            "محصل":          ("WAT-COL",      "محصل فواتير مياه"),
        },
        "SAN": {
            "مدير":          ("SAN-MGR",      "مدير مديرية الصرف الصحي"),
            "رئيس قسم":      ("SAN-SEC-HEAD", "رئيس قسم صرف صحي"),
            "فني":           ("SAN-TECH",     "فني صرف صحي"),
            "مشغل محطة":     ("SAN-OPS",      "مشغل محطة معالجة"),
            "سائق شفط":      ("SAN-DRV",      "سائق شفط صهاريج"),
        },
        "CUS": {
            "مدير":          ("CUS-MGR",      "مدير خدمات المشتركين"),
            "موظف":          ("CUS-EMP",      "موظف خدمات المشتركين"),
            "محصل":          ("CUS-COL",      "محصل فواتير"),
            "كاشير":         ("CUS-CASH",     "كاشير"),
        },
        "MNT": {
            "مدير":          ("MNT-MGR",      "مدير الصيانة"),
            "فني":           ("MNT-TECH",     "فني صيانة"),
            "كهربائي":       ("MNT-ELEC",     "كهربائي"),
            "لحام":          ("MNT-WLD",      "لحام"),
        },
        "DEP": {
            "امين مستودع":   ("DEP-KPR",      "امين المستودع"),
            "مساعد":         ("DEP-ASST",     "مساعد امين مستودع"),
        },
        "FIN": {
            "مدير مالي":     ("FIN-MGR",      "مدير مالي"),
            "محاسب":         ("FIN-ACC",      "محاسب"),
            "مراقب مالي":    ("FIN-AUD",      "مراقب مالي"),
        },
    }

    def resolve(self, job_title: str, directorate_code: Optional[str]) -> dict:
        jt = (job_title or "").strip()
        dcode = (directorate_code or "").strip().upper() or None
        titles = self.TITLES_BY_DIRECTORATE.get(dcode, {}) if dcode else {}

        for key, (code, full_title) in titles.items():
            if jt == key or jt.startswith(key):
                return {
                    "code": code,
                    "full_title": full_title,
                    "directorate_code": dcode,
                }

        fallback = jt or "موظف"
        fallback_code = f"{dcode}-GEN" if dcode else "GEN"
        return {
            "code": fallback_code,
            "full_title": fallback,
            "directorate_code": dcode,
        }


job_title_resolver = JobTitleResolver()
