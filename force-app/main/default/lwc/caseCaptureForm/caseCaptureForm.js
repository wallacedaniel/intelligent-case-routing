import { LightningElement, track, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import TYPE_FIELD from '@salesforce/schema/Case.Type';
import PRIORITY_FIELD from '@salesforce/schema/Case.Priority';
import PRODUCT_FIELD from '@salesforce/schema/Case.Product__c';
import createCase from '@salesforce/apex/CaseController.createCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseCaptureForm extends LightningElement {
    @track caseRecord = {
        Subject: '',
        Description: '',
        Type: '',
        Priority: 'Medium',
        Product__c: ''
    };
    
    @track typeOptions = [];
    @track priorityOptions = [];
    @track productOptions = [];
    @track loading = false;
    @track error;
    
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo;
    
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: TYPE_FIELD })
    typePicklistValues({error, data}) {
        if (data) {
            this.typeOptions = data.values;
        } else if (error) {
            console.error('Error loading type picklist values', error);
        }
    }
    
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: PRIORITY_FIELD })
    priorityPicklistValues({error, data}) {
        if (data) {
            this.priorityOptions = data.values;
        } else if (error) {
            console.error('Error loading priority picklist values', error);
        }
    }
    
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: PRODUCT_FIELD })
    productPicklistValues({error, data}) {
        if (data) {
            this.productOptions = data.values;
        } else if (error) {
            console.error('Error loading product picklist values', error);
        }
    }
    
    handleInputChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        this.caseRecord[field] = value;
    }
    
    submitCase() {
        this.loading = true;
        
        createCase({ caseData: this.caseRecord })
            .then(result => {
                this.loading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Case created successfully',
                        variant: 'success'
                    })
                );
                
                // Reset form
                this.resetForm();
                
                // Navigate to case detail
                this.dispatchEvent(new CustomEvent('casecreated', {
                    detail: { caseId: result }
                }));
            })
            .catch(error => {
                this.loading = false;
                this.error = error.body.message;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error creating case: ' + this.error,
                        variant: 'error'
                    })
                );
            });
    }
    
    resetForm() {
        this.caseRecord = {
            Subject: '',
            Description: '',
            Type: '',
            Priority: 'Medium',
            Product__c: ''
        };
    }
}