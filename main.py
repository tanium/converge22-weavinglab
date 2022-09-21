#!/usr/bin/env python3

import requests

# constants
TANIUM_SERVER = "CHANGE_ME"
API_TOKEN = "CHANGE_ME"

def run_example_report():
    """
    Example function of how to execute a simple graphql query against 
    a Tanium server to pull the example query we built in the previous lab. 
    """
    query = '''
    {
        endpoints {
            edges {
                node {
                    name
                    ipAddress
                    os {
                        name
                    }
                }
            }
        }
    }
    '''

    r = execute_query(TANIUM_SERVER, API_TOKEN, query)

    # print the results. Each line should have the endpoint's name and 
    # ip address.
    for edges in r.json()['data']['endpoints']['edges']:
        print(
            edges['node']['name'], 
            edges['node']['ipAddress'],
            edges['node']['os']['name'],
        )

def execute_query(ts: str, token: str, query: str) -> requests.Response:
    """
    graphQLQuery will execute the graphQL query against the Tanium server
    that is passed into this function. 

    parameter ts is the Tanium server to use.
    parameter token is the api token string generated from the ts gui.
    parameter query is the query to execute. Example: '{now}'.
    """

    jsonObj = {'query': query}

    return requests.post(ts + "/plugin/products/gateway/graphql",
                         json=jsonObj,
                         headers={'session': token},
                         verify=False)


def main():
    """
    Main function of program. 
    """

    run_example_report()

if __name__ == '__main__':
    main()
