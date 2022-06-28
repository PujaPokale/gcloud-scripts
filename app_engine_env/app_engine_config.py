import requests
import json

data_dict =  { "name": "app_name",
 "id": "project_id", 
 "config_file": "app.yaml",
 "authDomain":"controls_who_can_access_this_app", 
 "locationId": "location",
 "codeBucket": "storage_bucket_name",
 "defaultCookieExpiration": "50.s",
 "servingStatus": "UNSPECIFIED"}


url = 'https://appengine.googleapis.com/v1/apps'

res = requests.post(url, data=json.dumps(data_dict))
print(res.text)
