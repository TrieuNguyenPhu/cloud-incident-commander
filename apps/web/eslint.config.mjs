import { defineConfig, globalIgnores } from "eslint/config";
import js from "@eslint/js";
import ts from "typescript-eslint";
import react from "eslint-plugin-react";
import hooks from "eslint-plugin-react-hooks";
import a11y from "eslint-plugin-jsx-a11y";

export default defineConfig([
  globalIgnores([".next/**", "out/**", "next-env.d.ts"]),
  js.configs.recommended,
  ts.configs.recommended,
  {
    files: ["**/*.{ts,tsx}"],
    extends: [
      react.configs.flat.recommended,
      react.configs.flat["jsx-runtime"],
      hooks.configs.flat.recommended,
      a11y.flatConfigs.recommended,
    ],
    settings: { react: { version: "detect" } },
  },
]);
