"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const jsx_runtime_1 = require("react/jsx-runtime");
const react_1 = require("react");
const harmony_plugin_client_lib_1 = require("@mplab_harmony/harmony-plugin-client-lib");
const MultipleUIComponentsWithLabel = (props) => {
    const symbolsComponent = [];
    const [labelNames, setLabelNames] = (0, react_1.useState)([]);
    const [symbols, setSymbols] = (0, react_1.useState)([]);
    (0, react_1.useEffect)(() => {
        harmony_plugin_client_lib_1.symbolUtilApi
            .getSymbols(props.componentId, props.symbolsArray)
            .then((e) => {
            setLabelNames(e);
        });
        harmony_plugin_client_lib_1.symbolUtilApi.getSymbolTypes(props.componentId, props.symbolsArray).then((e) => {
            setSymbols(e);
        });
    }, [props.componentId, props.symbolsArray]);
    labelNames.map((e) => {
        const labelName = e.label;
        const isComponentVisible = e.visible;
        if (labelName !== null && symbols.length !== 0 && isComponentVisible) {
            symbolsComponent.push((0, jsx_runtime_1.jsx)("label", { children: e.label }));
            symbolsComponent.push((0, jsx_runtime_1.jsx)(harmony_plugin_client_lib_1.DefaultControl, { symbol: e }, e.symbolId));
        }
    });
    return ((0, jsx_runtime_1.jsx)("div", Object.assign({ className: 'grid', style: { width: '30rem' } }, { children: symbolsComponent.map((component, index) => ((0, jsx_runtime_1.jsx)("div", Object.assign({ className: 'col-6 flex align-self-center flex align-items-center' }, { children: component }), index))) })));
};
exports.default = MultipleUIComponentsWithLabel;
