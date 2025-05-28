import { LightningElement, api, wire, track } from 'lwc';
import getCaseDetails from '@salesforce/apex/CaseController.getCaseDetails';
import addCaseComment from '@salesforce/apex/CaseController.addCaseComment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseDetail extends LightningElement {
    @api recordId;
    @track case;
    @track error;
    @track loading = false;
    @track newComment = '';

    @wire(getCaseDetails, { caseId: '$recordId' })
    wiredCase({ error, data }) {
        if (data) {
            this.case = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body.message;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error loading case details: ' + this.error,
                    variant: 'error'
                })
            );
        }
    }

    handleCommentChange(event) {
        this.newComment = event.target.value;
    }

    addComment() {
        if (!this.newComment.trim()) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter a comment',
                    variant: 'error'
                })
            );
            return;
        }

        this.loading = true;
        addCaseComment({ caseId: this.recordId, commentBody: this.newComment })
            .then(() => {
                this.loading = false;
                this.newComment = '';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Comment added successfully',
                        variant: 'success'
                    })
                );
                // Refresh the case details
                return getCaseDetails({ caseId: this.recordId });
            })
            .then(data => {
                if (data) {
                    this.case = data;
                }
            })
            .catch(error => {
                this.loading = false;
                this.error = error.body.message;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error adding comment: ' + this.error,
                        variant: 'error'
                    })
                );
            });
    }
}
