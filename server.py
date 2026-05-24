import http.server,json,os,sys
PORT=int(sys.argv[1]) if len(sys.argv)>1 else 8000
SYNC_FILE=os.path.join(os.path.dirname(os.path.abspath(__file__)),'sync_data.json')

class Handler(http.server.SimpleHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin','*')
        self.send_header('Access-Control-Allow-Methods','GET,POST,OPTIONS')
        self.send_header('Access-Control-Allow-Headers','Content-Type')
        self.end_headers()
    def _send_json(self,data,code=200):
        self.send_response(code)
        self.send_header('Content-Type','application/json')
        self.send_header('Access-Control-Allow-Origin','*')
        self.end_headers()
        self.wfile.write(json.dumps(data,ensure_ascii=False).encode('utf-8'))
    def do_POST(self):
        path=self.path.split('?')[0]
        if path=='/api/save':
            length=int(self.headers.get('Content-Length',0))
            body=self.rfile.read(length)
            try:
                with open(SYNC_FILE,'w',encoding='utf-8') as f:
                    json.dump(json.loads(body),f,ensure_ascii=False)
                self._send_json({'ok':True})
            except Exception as e:
                self._send_json({'ok':False,'error':str(e)},500)
        elif path=='/api/load':
            if os.path.exists(SYNC_FILE):
                with open(SYNC_FILE,'r',encoding='utf-8') as f:
                    self._send_json(json.load(f))
            else:
                self._send_json({'date':'','data':None})
        else:
            self._send_json({'error':'not found'},404)
    def do_GET(self):
        p=self.path.split('?')[0]
        if p.startswith('/api/'):
            self.do_POST()
        else:
            super().do_GET()

if __name__=='__main__':
    print('Server on port '+str(PORT)+' - sync enabled')
    http.server.HTTPServer(('0.0.0.0',PORT),Handler).serve_forever()
