import { LightningElement, wire, track } from 'lwc';
import getMyCases from '@salesforce/apex/CaseController.getMyCases';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseList extends LightningElement {
    @track cases;
    @track error;
    @track loading = false;

    @wire(getMyCases)
    wiredCases({ error, data }) {
        if (data) {
            this.cases = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body.message;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error loading cases: ' + this.error,
                    variant: 'error'
                })
            );
        }
    }

    handleCaseClick(event) {
        const caseId = event.currentTarget.dataset.caseId;
        this.dispatchEvent(
            new CustomEvent('casedetail', {
                detail: { caseId: caseId }
            })
        );
    }
}
