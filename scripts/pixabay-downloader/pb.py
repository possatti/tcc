#!/usr/bin/python3

"""
pd.py
    Downloads images from Pixabay's API.

Usage:
    ./pb.py pixabay_token images_dir number_of_coutries images_per_coutry
"""

import os
import sys
import json
import requests

pb_token = sys.argv[1]
images_dir = sys.argv[2]
number_of_coutries = int(sys.argv[3])
images_per_coutry = int(sys.argv[4])

search_terms = ['Russia', 'Canada', 'China', 'United', 'Brazil', 'Australia', 'India', 'Argentina', 'Kazakhstan', 'Algeria', 'Democratic', 'Saudi', 'Mexico', 'Indonesia', 'Sudan', 'Libya', 'Iran', 'Mongolia', 'Peru', 'Chad', 'Niger', 'Angola', 'Mali', 'South', 'Colombia', 'Ethiopia', 'Bolivia', 'Mauritania', 'Egypt', 'Tanzania', 'Nigeria', 'Venezuela', 'Pakistan', 'Namibia', 'Mozambique', 'Turkey', 'Chile', 'Zambia', 'Myanmar', 'Afghanistan', 'France', 'Somalia', 'Central', 'South', 'Ukraine', 'Madagascar', 'Botswana', 'Kenya', 'Yemen', 'Thailand', ]

os.mkdir(images_dir)

for i, term in enumerate(search_terms):
    if i > number_of_coutries:
        break

    print('Trying:', term)

    # Request images
    payload = {'key': pb_token, 'q': term, 'image_type': 'photo', 'safesearch': 'true', 'per_page': images_per_coutry}
    r = requests.get('https://pixabay.com/api/', params=payload)
    print('Requesting:', r.url)
    j = r.json()

    # Download each image
    for hit in j['hits']:
        image_url = hit['webformatURL']
        image_r = requests.get(image_url)
        filename = image_url.split("/")[-1]
        print('Downloading:', image_url)
        with open(os.path.join(images_dir, filename), 'wb') as image_file:
            image_file.write(image_r.content)
