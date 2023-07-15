import { LightningElement, api } from "lwc";
import BEER_IMAGE from "@salesforce/resourceUrl/beerImage";

export default class BeerTile extends LightningElement {
  @api beerRecord;
  beerImage = BEER_IMAGE;

  connectedCallback() {
    console.log("beerRecord ", this.beerRecord);
  }

  handleAddToCart() {
    const event = new CustomEvent("add", {
      detail: this.beerRecord.Id
    });
    this.dispatchEvent(event);
  }
}
