def validate_orders(order):
    """
    Validates the order data.

    Args:
        order (dict): The order data to validate.

    Returns:
        tuple[bool, str]: (True, "Order is valid") si es válida; (False, motivo) si no.
    """
    required_fields = ["customerName", "email", "items", "total_amount","orderDate"]
    
    for field in required_fields:
        if field not in order:
            return False, f"Missing required field: {field}"
    
    if not isinstance(order["items"], list) or len(order["items"]) == 0:
        return False, f"Items must be a non-empty list."
    
    if not isinstance(order["total_amount"], (int, float)) or order["total_amount"] <= 0:
        return False, f"Total amount must be a positive number."

    for item in order["items"]:
       
        if "productId" not in item or "quantity" not in item or "price" not in item:
            return False, f"Each item must contain 'productId', 'quantity'"
        if not isinstance(item["quantity"], int) or item["quantity"] <= 0:
            return False, f"Item quantity must be a positive integer."
     
    
    return True, "Order is valid"