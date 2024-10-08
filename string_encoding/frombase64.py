import base64
import json

def decode_base64(encoded_str):
    """
    Decodes a Base64-encoded string back to its original JSON string.

    Args:
        encoded_str (str): The Base64-encoded string.

    Returns:
        dict: The decoded JSON object as a dictionary.
    """
    # Step 1: Decode the Base64 string
    decoded_bytes = base64.b64decode(encoded_str)

    # Step 2: Convert the decoded bytes back to a string
    decoded_str = decoded_bytes.decode('utf-8')

    # Step 3: Parse the string into a dictionary (JSON)
    json_data = json.loads(decoded_str)

    return json_data

# Example usage:
encoded_base64 = input("Enter base64 message : ")
decoded_json = decode_base64(encoded_base64)
print(decoded_json)
