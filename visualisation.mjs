import * as rawgraphsCore from "@rawgraphs/rawgraphs-core";
import * as rawgraphsCharts from "@rawgraphs/rawgraphs-charts"

// Check if the `chart` function is included in the module's exports
console.log(rawgraphsCore.chart);

// defining some data.
const userData = [
  { size: 10, price: 2, cat: "a" },
  { size: 12, price: 1.2, cat: "a" },
  { size: 1.3,price: 2, cat: "b" },
  { size: 1.5,price: 2.2, cat: "c" },
  { size: 10, price: 4.2, cat: "b" },
  { size: 10, price: 6.2, cat: "c" },
  { size: 12, price: 2.2, cat: "b" },
]


// define a mapping between dataset and the visual model
const mapping = {
  x: { value: "size" },
  y: { value: "price" },
  color: { value: "cat" },
}

console.log(rawgraphsCharts.bubblechart);
//instantiating the chart
// try {
//     const viz = rawgraphsCore.chart(bubblechart, {
//       data: userData,
//       mapping,
//     })
// } catch (error) {
//     console.log(error);
// }
