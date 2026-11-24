import azure.functions as func
import datetime
import json
import logging
from helpers import validate_orders

app = func.FunctionApp()

@app.route(route="OrderTrigger", methods=["POST"],auth_level=func.AuthLevel.ANONYMOUS)
def order_trigger(req: func.HttpRequest) -> func.HttpResponse:
    try:
        order_data = req.get_json()
    except ValueError:
        return func.HttpResponse("Invalid JSON payload", status_code=400)

    is_valid, message = validate_orders(order_data)
    if not is_valid:
        return func.HttpResponse(message, status_code=400)

    return func.HttpResponse(
        json.dumps({"message": "Order received successfully"}),
        status_code=200,
        mimetype="application/json"
    )