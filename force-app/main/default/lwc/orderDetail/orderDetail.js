import { LightningElement, wire, track } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import getOrderAndItsItems from "@salesforce/apex/BeerController.getOrderAndItsItems";

export default class OrderDetail extends LightningElement {
  orderId;
  @track
  order;
  @track
  orderItems;

  @wire(CurrentPageReference) currentPageReference(pageRef) {
    console.log("pageRef ", pageRef);
    this.orderId = pageRef.state.c__orderId;
    console.log("orderId ", this.orderId);
  }

  connectedCallback() {
    this.getOrder();
  }

  getOrder() {
    getOrderAndItsItems({ orderId: this.orderId })
      .then((result) => {
        console.log("result ", result);
        this.order = result.order;
        this.orderItems = result.orderItems;
      })
      .catch((error) => {
        console.log("error ", error);
      });
  }
}
