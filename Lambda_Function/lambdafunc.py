import re

def handler(event, context):
    try:
        # Safely navigate the event structure
        request = event['Records'][0]['cf']['request']
        viewerCountry = request.get('headers', {}).get('accept-language')
        
        if viewerCountry:
            countryCode = viewerCountry[0]['value']
            if re.match(r'^es', countryCode):
                domainName = "es-bucket-transl-ppline.s3.us-east-1.amazonaws.com"
                request['origin']['s3']['domainName'] = domainName
                request['headers']['host'] = [{'key': 'host', 'value': domainName}]
            elif re.match(r'^pt', countryCode):
                domainName = "pt-bucket-transl-ppline.s3.us-east-1.amazonaws.com"
                request['origin']['s3']['domainName'] = domainName
                request['headers']['host'] = [{'key': 'host', 'value': domainName}]
        
        return request
    except KeyError as e:
        print(f"Missing key in event: {e}")
        raise
    except Exception as e:
        print(f"Unhandled error: {e}")
        raise