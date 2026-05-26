import requests

url = "https://103.27.207.136.nip.io/api/v1/validate-listing"
listing_data = '''{
    "device_id":"test_id_from_flutter",
    "listing_name":"Kos Nyaman",
    "area_name":"UGM Yogyakarta",
    "price":500000,
    "address_specificity": "tidakTahu",
    "photos_match_location": "ya",
    "info_consistency": "tidakTahu",
    "dp_requested": false,
    "pressure_to_transfer": false,
    "owner_willing_videocall": true,
    "recent_video_provided": "tidakTahu",
    "bank_account_name_match": "tidakTahu",
    "payment_details_explained": "tidakTahu",
    "room_facilities":["Kasur", "Lemari"]
}'''

files = {
    'listing_data': (None, listing_data)
}

response = requests.post(url, files=files)
print(response.status_code)
print(response.text)
