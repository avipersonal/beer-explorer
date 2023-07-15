import { LightningElement, wire } from "lwc";
import searchBeer from "@salesforce/apex/BeerController.searchBeer";
import cartIco from "@salesforce/resourceUrl/cartIco";
import getCartId from "@salesforce/apex/BeerController.getCartId";
import createCartItem from "@salesforce/apex/BeerController.createCartItem";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";

export default class BeerList extends NavigationMixin(LightningElement) {
  beerRecords;
  searchParameter;
  cartImage = cartIco;
  itemsInCart = 0;
  activeCartId;
 

  connectedCallback() {
    this.defaultId();
  }

  defaultId() {
    getCartId()
      .then((result) => {
        const cartInfo = JSON.parse(result);
        console.log("cartInfo ", cartInfo);
        this.itemsInCart = cartInfo.count;
        this.activeCartId = cartInfo.cartId;
      })
      .catch((error) => {
        this.activeCartId = undefined;
        console.log(error);
      });
  }

  redirectToBeerDetail(event) {
    event.preventDefault();
    this[NavigationMixin.Navigate]({
      type: "standard__navItemPage",
      attributes: {
        apiName: "Cart_Detail"
      },
      state: {
        c__cartId: this.activeCartId
      }
    });
  }

  addToCart(event) {
    const beerId = JSON.parse(JSON.stringify(event.detail));
    console.log("beerId ", beerId);
    const beerRecord = this.beerRecords.find((value) => value.Id === beerId);
    console.log("beerRecord ", beerRecord);
    createCartItem({
      beerId: beerRecord.Id,
      cartId: this.activeCartId,
      Amount: beerRecord.Price__c
    })
      .then((result) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Suceess",
            message: "Item Added Successfully!! Item Id: " + result,
            variant: "success"
          })
        );
      })
      .catch((error) => {
        console.log("error ", error);
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error occured",
            message: "Default coupon expired. please either change date of default coupon or increase quantity if zero.",
            variant: "error"
          })
        );
      });
  }

  @wire(searchBeer) searchBeerHandler({ data, error }) {
    this.beerRecords = data;
  }

  handleSearch(event) {
    this.searchParameter = event.detail;

    searchBeer({ searchParam: this.searchParameter })
      .then((result) => {
        this.beerRecords = result;
      })
      .catch((error) => {
        console.log("error " + error);
      });
  }
}
