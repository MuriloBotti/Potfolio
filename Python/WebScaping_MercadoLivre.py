
import requests
from bs4 import BeautifulSoup
import pandas as pd
from datetime import date
import sys

lista_produtos = []

print("Welcome to Mercado Livre's Data Scraping!")


product_choice = input('What product do you want to search? ')
product_name = product_choice.replace(' ', '-').lower()
url_base = 'https://lista.mercadolivre.com.br/'
response = requests.get(url_base + product_name)
site = BeautifulSoup(response.text, 'html.parser')

products = site.findAll('div', attrs={'class': 'andes-card andes-card--flat andes-card--default ui-search-result shops__cardStyles ui-search-result--core andes-card--padding-default'})

for product in products:
    title = product.find('h2', attrs={'class': 'ui-search-item__title shops__item-title'})
    link = product.find('a', attrs={'class': 'ui-search-link'})
    
    amount = product.find('span', attrs={'class': 'price-tag-fraction'})
    cents = product.find('span', attrs={'class': 'price-tag-cents'})
    currency = product.find('span', attrs={'price-tag-symbol'})

    rating = product.find('span', attrs={'andes-visually-hidden'})
    details = product.find('span', attrs={'ui-search-item__group__element ui-search-item__variations-text shops__items-group-details'})

    lista_produtos.append([
        title.text,
        currency.text,
        amount.text,
        cents.text if cents else '',
        rating.text if rating else '',
        details.text if details else '',
        link['href']
    ])

data_texto = date.today().strftime("%d-%m-%Y")
nome_excel = 'DataScraping_MercadoLivre_' + product_name + '_' + data_texto + '.xlsx'

produtos_excel = pd.DataFrame(lista_produtos, columns=[
    'Title',
    'Currency', 
    'Amount', 
    'Cents', 
    'Rating', 
    'Details', 
    'Link'])

produtos_excel.to_excel(nome_excel, index=False)
print('\nData Scraping Finished!')
sys.exit()