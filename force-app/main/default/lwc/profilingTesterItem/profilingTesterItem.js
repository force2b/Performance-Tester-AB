import { LightningElement, api } from 'lwc';

export default class profilingTesterItem extends LightningElement {

    @api value;
    @api label;
    @api minDecimals = 0;
    @api maxDecmails = 0;

}