const { encode } = require ('@api3/airnode-abi');
const { decode } = require ('@api3/airnode-abi');

// Add your parameters here, then copy the encoded data to be used as parameters in the makeRequest function.
const params = [
   { type: 'string', name: 'part', value: 'statistics' }, 
   { type: 'string', name: 'id', value: 'Jfk6-lZUUvQ' }, 
   { type: 'string', name: '_path', value: 'items.0.statistics.viewCount' },
   { type: 'string', name: '_type', value: 'int256' }
];

const encodedData = encode(params);
const decodedData = decode(encodedData);

console.log(encodedData);
console.log(decodedData);
