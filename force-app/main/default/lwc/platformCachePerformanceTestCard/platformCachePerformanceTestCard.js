import { LightningElement, api, track } from 'lwc';
import ChartJS from '@salesforce/resourceUrl/chartjs_v280';
import { loadScript } from 'lightning/platformResourceLoader';
export default class PlatformCachePerformanceTestCard extends LightningElement {

    @api testData;
    @api testType;
    chart;
    labelCounter = 0;

    /**
     * @description Base (default) chart configuration. Modified by loadChart()
     */
    chartConfig = {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'Test 1',
                data: [],
                backgroundColor: [
                    'rgba(255, 99, 132, 0.2)'
                ],
                borderColor: [
                    'rgba(255, 99, 132, 1)'
                ],
                borderWidth: 1,
                fill: false
            },
            {
                label: 'Test 2',
                data: [],
                backgroundColor: [
                    'rgba(54, 162, 235, 0.2)'
                ],
                borderColor: [
                    'rgba(54, 162, 235, 1)'
                ],
                borderWidth: 1,
                fill: false
            }
        ]
        },
        options: {
            scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero: true
                    }
                }]
            },
            elements: {
                point:{
                    radius: 0
                }
            },
            maintainAspectRatio: false,
            responsive: true
        }
    };

    get chartId() {
        return 'Chart-' + this.testType;
    }

    /**
     * @description Called by the parent component to initialize the chart in the UI by setting the height and series labels
     */
    @api
    loadChart() {
        loadScript(this, ChartJS)
            .then(() => {
                if (this.chart && this.chart.data && this.chart.data.datasets) {
                    // chart already exists, just update the data
                    this.chart.data.datasets = this.datasets;
                    this.chart.update();
                } else {
                    // create the chart and populate it
                    const canvas = document.createElement("canvas");
                    canvas.height = 300;
                    this.template.querySelector("div.chart").appendChild(canvas);
                    const ctx = canvas.getContext("2d");
                    this.chart = new window.Chart(ctx, this.chartConfig);
                    this.chart.canvas.parentNode.style.height = '300px';
                    this.chart.data.datasets[0].label = this.testData.ModeA.Label;
                    this.chart.data.datasets[1].label = this.testData.ModeB.Label;
                    this.chart.update();
                }
            })
            .catch(error => {
                console.log(error);
            });
    }

    /**
     * @description Called by the parent component to allow the chart to update
     * @param duration - push this duration into the data set
     * @param series - which of the 2 series on the chart to update. TestA=Series0; TestB=Series1
     */
    @api
    updateChart(duration, series) {
        if (series === 0) {
            this.chart.data.labels.push(this.labelCounter++);
        }
        this.chart.data.datasets[series].data.push(duration);
        if (series === 1) {
            this.chart.update();
        }
    }
}