import requests

def get_url_info(url):
    info = {}

    try:
        # Realizar la solicitud GET
        response = requests.get(url)

        # Obtener el código de estado
        info['status_code'] = response.status_code

        # Obtener los encabezados
        info['headers'] = response.headers

        # Obtener las cookies
        info['cookies'] = response.cookies.get_dict()

        # Obtener el contenido de la respuesta
        info['content'] = response.content.decode('utf-8', errors='ignore')

        # Obtener la URL redirigida (si hubo redirección)
        info['url'] = response.url

        # Obtener el tiempo de respuesta
        info['elapsed_time'] = response.elapsed.total_seconds()

    except requests.RequestException as e:
        info['error'] = str(e)

    return info

def main():
    # url = "https://193.150.166.1:5000/gw/dbapi/banking/transactions/v2"
    url = "https://193.150.166.1:5000"
    info = get_url_info(url)

    print("\nInformación de la URL:", url)
    print("Código de Estado:", info.get('status_code'))
    print("Encabezados:\n", info.get('headers'))
    print("Cookies:\n", info.get('cookies'))
    print("Contenido:\n", info.get('content'))
    print("URL Redirigida:", info.get('url'))
    print("Tiempo de Respuesta (segundos):", info.get('elapsed_time'))
    if 'error' in info:
        print("Error:", info['error'])

if __name__ == "__main__":
    main()
