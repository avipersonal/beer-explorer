import { LightningElement, wire, track } from "lwc";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import getItems from "@salesforce/apex/BeerController.getItems";
import { deleteRecord } from "lightning/uiRecordApi";
import getCoupon from "@salesforce/apex/BeerController.getCoupon";
import saveAddress from "@salesforce/apex/BeerController.saveAddress";
import getAddresses from "@salesforce/apex/BeerController.getAddresses";
import createOrder from "@salesforce/apex/BeerController.createOrder";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class CartDetail extends NavigationMixin(LightningElement) {
  cartId;
  @track
  items;
  couponName;
  couponValue = 0;
  error;
  isProceed;
  totalAddress;
  selectedAddress;
  @track
  addresses = [];
  totalItems = 0;
  isCoupon = false;
  grandTotal = 0.0;

  @track
  addr = {
    Street__c: "",
    City__c: "",
    State__c: "",
    Country__c: "",
    Postal_Code__c: ""
  };

  @wire(CurrentPageReference) setCurrentPageReference(pageRef) {
    if (pageRef) {
      console.log("PageReference ", pageRef);
      this.cartId = pageRef.state.c__cartId;
    }
  }

  connectedCallback() {
    this.cartItems();
    this.getAddresses();
  }

  handleCoupon(event) {
    event.preventDefault();
    this.isCoupon = true;
  }

  continueShopping() {
    this[NavigationMixin.Navigate]({
      type: "standard__navItemPage",
      attributes: {
        apiName: "Beer_Explorer"
      }
    });
  }

  getAddresses() {
    getAddresses()
      .then((result) => {
        console.log("result address", result);
        this.addresses = result;
        this.totalAddress = this.addresses.length;
      })
      .catch((error) => {
        console.log(error);
      });
  }

  placeOrder() {
    createOrder({
      totalAmount: this.grandTotal,
      cartId: this.cartId,
      addressId: this.selectedAddress.Id
    })
      .then((result) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Order Created!",
            message:
              "Your Order is Created. Your order number is " + result.Name,
            variant: "success"
          })
        );
        this[NavigationMixin.Navigate]({
          type: "standard__navItemPage",
          attributes: {
            apiName: "Order_Detail"
          },
          state: {
            c__orderId: result.Id
          }
        });
      })
      .catch((error) => {
        console.log(error);
      });
  }

  proceedCheckout() {
    this.isProceed = true;
  }

  handleAddressChange(event) {
    let name = event.target.name;
    let value = event.target.value;
    this.addr[name] = value;
  }

  addNewAddress() {
    this.totalAddress = 0;
  }

  selectAddress(event) {
    const addressId = event.detail;
    console.log(addressId);

    if (!addressId) {
      alert("Please select address for placing order");
      return;
    }
    this.selectedAddress = this.addresses.find((address) => {
      let adFound;
      if (address.Id === addressId) {
        adFound = address;
      }
      return adFound;
    });
    console.log(this.selectedAddress);
  }

  handleSaveAddress() {
    saveAddress({ addressString: JSON.stringify(this.addr) })
      .then((result) => {
        console.log("saved address ", result);
        this.addresses.push(result);
        this.totalAddress = 1;
      })
      .catch((error) => {
        console.log("address error ", error);
      });
  }

  handleCouponValue(event) {
    this.couponName = event.target.value;
  }

  applyCoupon() {
    getCoupon({ couponName: this.couponName })
      .then((result) => {
        console.log("result ", result);
        if (result?.Price__c !== undefined && result?.Price__c !== null) {
          this.couponValue = result.Price__c;
          console.log("couponValue", this.couponValue);
          this.grandTotal = this.grandTotal - this.couponValue;
        } else {
          alert("Please enter a valid coupon");
          this.grandTotal = this.grandTotal + this.couponValue;
          this.couponValue = 0;
        }
      })
      .catch((error) => {
        console.log(error);
      });
  }

  cartItems() {
    console.log("cartId ", this.cartId);
    getItems({ cartId: this.cartId })
      .then((result) => {
        console.log("result by items ", result);
        this.items = JSON.parse(result); //If there is a error in then function, then it will also go in catch
        this.totalItems = this.items.length;
        this.error = undefined;
        for (let i = 0; i < this.totalItems; i++) {
          console.log(this.items[i].Total_Amount__c);
          this.grandTotal += this.items[i].Total_Amount__c;
        }
        console.log("grand total ", this.grandTotal);
      })
      .catch((error) => {
        console.log("error when getting items " + error);
        this.error = error;
        this.items = undefined;
        this.totalItems = 0;
      });
  }

  deleteItem(event) {
    let cartItemId = event.detail;
    console.log("cartItemId ", cartItemId);
    const deletedItem = this.items.find((value) => value.Id === cartItemId);
    let index = this.items.indexOf(deletedItem);
    deleteRecord(cartItemId)
      .then(() => {
        console.log("record deleted");
        console.log("deletedItem and Index ", deletedItem.Beer__r.Name, index);
        this.items.splice(index, 1);
        this.totalItems = this.items.length;
        this.grandTotal = this.grandTotal - deletedItem.Total_Amount__c;
        console.log("Grandtotal ", this.grandTotal);
      })
      .catch((error) => {
        console.log("error ", error);
      });
  }
}
