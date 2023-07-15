import { LightningElement, api } from "lwc";

export default class AddressDetails extends LightningElement {
  @api address;

  giveAddressId() {
    this.dispatchEvent(
      new CustomEvent("address", {
        detail: this.address.Id
      })
    );
  }
}
