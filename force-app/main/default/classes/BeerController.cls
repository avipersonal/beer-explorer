public with sharing class BeerController {
  @AuraEnabled(cacheable=true)
  public static list<sobject> searchBeer(string searchParam) {
    string query;
    string refinedQuery;
    if (searchParam != null && string.isNotBlank(searchParam)) {
      string likeParam = '%' + searchParam + '%';
      query = 'Select Id__c, Alcohol__c, Name, brewery_id__c, brewery_name__c, Consumed_Quantity__c, Image__c, Tags__c, Total_Quantity__c, Remaining_Quantity__c, Price__c from Beer__c where Name like :likeParam limit 50';
    } else {
      query = 'Select Id__c, Alcohol__c, Name, brewery_id__c, brewery_name__c, Consumed_Quantity__c, Image__c, Tags__c, Total_Quantity__c, Remaining_Quantity__c, Price__c from Beer__c Limit 50';
    }
    refinedQuery = string.escapeSingleQuotes(query);
    list<sobject> beerList = Database.query(refinedQuery);
    return beerList;
  }

  public static string generateCartId() {
    string allChar = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890_';
    string ranId;
    for (integer i = 0; i < 16; i++) {
      integer position =
        (Math.roundToLong(allChar.length() * Math.random())).intValue() - 1;
      string indexEl = allChar.substring(position, position + 1);
      ranId += indexEl;
    }
    return ranId;
  }

  @AuraEnabled
  public static coupon__c getCoupon(string couponName) {
    return getCouponInformation(couponName);
  }

  public static Coupon__c getCouponInformation(string couponName) {
    try {
      return [
        SELECT Id, Price__c
        FROM Coupon__c
        WHERE
          Expired__c = FALSE
          AND (Remaining_Quantity__c > 0
          OR Name = 'Default')
          AND Name = :couponName
      ];
    } catch (Exception e) {
      return null;
    }
  }

  @AuraEnabled(cacheable=false)
  public static string getCartId() {
    try {
      list<Cart__c> carts = [
        SELECT Id, Name
        FROM Cart__c
        WHERE
          Is_Active__c = TRUE
          AND Cart_Status__c = 'Open'
          AND User__c = :UserInfo.getUserId()
      ];
      if (carts != null && carts.size() > 0) {
        list<Cart_Item__c> items = [
          SELECT Id, Name, Item_Quantity__c
          FROM Cart_Item__c
          WHERE Cart__c = :carts[0].Id
        ];
        AggregateResult result = [
          SELECT SUM(Item_Quantity__c) itCounter
          FROM Cart_Item__c
          WHERE Cart__c = :carts[0].Id
        ];
        CartWrapper cartInfo = new CartWrapper();
        cartInfo.cartId = carts[0].Id;
        if (result.get('itCounter') != null) {
          cartInfo.count = (decimal) result.get('itCounter');
        } else {
          cartInfo.count = 0;
        }
        System.debug(cartInfo.count);
        cartInfo.cartItems = items;
        return JSON.serialize(cartInfo);
      } else {
        Cart__c defaultCart = new Cart__c();
        Coupon__c coupon = getCouponInformation('Default');
        defaultCart.Cart_Id__c = generateCartId();
        defaultCart.coupon__c = coupon.Id;
        defaultCart.Is_Active__c = true;
        defaultCart.User__c = UserInfo.getUserId();
        defaultCart.Cart_Status__c = 'Open';
        insert defaultCart;
        CartWrapper cartInfo = new CartWrapper();
        cartInfo.cartItems = null;
        cartInfo.count = 0;
        System.debug(' default cart Id ' + defaultCart.Id);
        cartInfo.cartId = defaultCart.Id;
        return JSON.serialize(cartInfo);
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static string createCartItem(
    string beerId,
    string cartId,
    double Amount
  ) {
    Cart_Item__c cartItem = new Cart_Item__c();
    Map<Id, Cart_Item__c> cartItemMap = getCartItems(cartId);
    if (cartItemMap.containskey(beerId)) {
      cartItem = cartItemMap.get(BeerId);
      cartItem.Item_Quantity__c += 1;
      cartItem.Item_Amount__c += Amount;
      update cartItem;
    } else {
      cartItem = new Cart_Item__c(
        beer__c = beerId,
        cart__c = cartId,
        Item_Amount__c = Amount,
        Item_Quantity__c = 1
      );
      insert cartItem;
    }
    return cartItem.Id;
  }

  public static map<Id, Cart_Item__c> getCartItems(string cartId) {
    Map<Id, Cart_Item__c> cartIdMap = new Map<Id, Cart_Item__c>();
    for (Cart_Item__c cartItem : [
      SELECT Id, Beer__c, Item_Quantity__c, Item_Amount__c, Cart__c
      FROM Cart_Item__c
      WHERE Cart__c = :cartId
    ]) {
      if (cartItem.Beer__c != null) {
        cartIdMap.put(cartItem.Beer__c, cartItem);
      }
    }
    return cartIdMap;
  }

  @AuraEnabled
  public static string getItems(string cartId) {
    try {
      list<Cart_Item__c> cartItems = [
        SELECT
          Id,
          Name,
          Total_Amount__c,
          Cart__c,
          Item_Quantity__c,
          Item_Amount__c,
          Beer__r.Name
        FROM Cart_Item__c
        WHERE Cart__c = :cartId
      ];
      return JSON.serialize(cartItems);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static Address_Book__c saveAddress(string addressString) {
    Address_Book__C address = (Address_Book__c) JSON.deserialize(
      addressString,
      Address_Book__c.class
    );
    System.debug('address ' + address);
    address.User__c = UserInfo.getUserId();
    insert address;
    return address;
  }

  @AuraEnabled
  public static list<Address_Book__c> getAddresses() {
    try {
      return [
        SELECT City__c, State__c, Street__c, Country__c, Postal_Code__c
        FROM Address_Book__c
        WHERE User__c = :UserInfo.getUserId()
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static Order__c createOrder(
    string cartId,
    integer totalAmount,
    string addressId
  ) {
    try {
      Order__c order = new Order__c(
        Cart__c = cartId,
        Shipping_Address__c = addressId,
        subTotal__c = totalAmount
      );
      insert order;
      Order__c orderC = [SELECT Id, Name FROM Order__c WHERE Id = :order.Id];

      list<Cart_Item__c> cartItems = (List<Cart_Item__c>) JSON.deserialize(
        getItems(cartId),
        list<Cart_Item__c>.class
      );
      system.debug('cartItems ' + cartItems);

      list<Order_Item__c> orderItems = new List<Order_Item__c>();
      for (Cart_Item__c cartItem : cartItems) {
        Order_Item__c orderItem = new Order_Item__c(
          Beer__c = cartItem.Beer__c,
          Ordered_Quantity__c = cartItem.Item_Quantity__c,
          Item_Price__c = cartItem.Item_Amount__c,
          Related_Order__c = order.Id
        );
        orderItems.add(orderItem);
      }
      if (!orderItems.isEmpty()) {
        insert orderItems;
      }

      Cart__c cart = new Cart__c();
      cart.Id = cartId;
      cart.Cart_Status__c = 'Closed';
      cart.Is_Active__c = false;
      update cart;
      return orderC;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static OrderWrapper getOrderAndItsItems(string orderId) {
    Order__c order = [
      SELECT
        subTotal__c,
        Order_Amount__c,
        Name,
        Shipping_Address__r.City__c,
        Shipping_Address__r.Street__c,
        Shipping_Address__r.State__c,
        Shipping_Address__r.Country__c,
        Shipping_Address__r.Postal_Code__c,
        (
          SELECT Beer__r.Name, Ordered_Quantity__c, Item_Price__c, Name
          FROM Order_Items__r
        )
      FROM Order__c
      WHERE Id = :orderId
    ];
    OrderWrapper wrapper = new OrderWrapper();
    wrapper.order = order;
    wrapper.orderItems = order.Order_Items__r;
    return wrapper;
  }

  public class CartWrapper {
    @AuraEnabled
    public decimal count { get; set; }
    @AuraEnabled
    public string cartId { get; set; }
    @AuraEnabled
    public list<Cart_Item__c> cartItems { get; set; }
  }

  public class OrderWrapper {
    @AuraEnabled
    public Order__c order { get; set; }
    @AuraEnabled
    public list<Order_Item__c> orderItems { get; set; }
  }
}
