import requests
import json

url = 'http://admin:admin@localhost:3000/api/dashboards/db'
headers = {'Content-Type': 'application/json', 'Accept': 'application/json'}

with open('node-exporter-full_rev31.json', 'r') as file:
    data = json.load(file)


payload = {
    'dashboard': data,
    'overwrite': True
}

response = requests.post(url, headers=headers, json=payload)

if response.status_code == 200:
    print('Dashboard imported successfully')
    print('Response:', response.json())
else:
    print('Failed to import dashboard')
    print('Status code:', response.status_code)
    print('Error message:', response.text)
import requests

