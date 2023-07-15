import { LightningElement, api } from "lwc";

export default class CartItem extends LightningElement {
  @api item;

  deleteCartItem() {
    const event = new CustomEvent("delete", {
      detail: this.item.Id
    });
    this.dispatchEvent(event);
  }
}
