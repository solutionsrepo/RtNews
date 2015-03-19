from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
import time
import json
import re

items_file = "items"
item_file = "item"

class MyRequestHandler (BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/articles":
            self.send_response(200)
            self.send_header("Content-type:", "text/json")
            self.wfile.write("\n")

            time.sleep(3)

            f = open(items_file, 'r')
            items = json.load(f)
            f.close()

            json.dump(items, self.wfile, indent=4)
        else:
            item_id = re.findall(r'/articles/(\d*)', self.path)

            f = open(item_file, 'r')
            item = json.load(f)
            f.close()

            json.dump(item, self.wfile, indent=4)


server = HTTPServer(("localhost", 8080), MyRequestHandler)

server.serve_forever()
