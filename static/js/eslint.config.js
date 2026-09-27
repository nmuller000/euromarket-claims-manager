// eslint.config.js
import js from "@eslint/js";
import globals from "globals";

export default [
    js.configs.recommended,
    {
        languageOptions: {
            globals: {
                ...globals.browser, // Standard browser globals
                apex: "readonly",    // APEX global object
                $v: "readonly",      // APEX get value function
                $s: "readonly",      // APEX set value function
                $x: "readonly",      // APEX get DOM element function
                apex_img_dir: "readonly" 
            }
        },
        rules: {
            "no-var": "error",       // Forces use of let/const
            "eqeqeq": "error",       // Forces use of ===
            "no-unused-vars": "warn" // Warns if you define but don't use
        }
    }
];