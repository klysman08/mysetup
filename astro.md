Prettier
```bash
  npm install --save-dev --save-exact prettier prettier-plugin-astro
```

Create a .prettierrc configuration file 
```bash
{
  "plugins": ["prettier-plugin-astro"],
  "overrides": [
    {
      "files": "*.astro",
      "options": {
        "parser": "astro",
      }
    }
  ]
}
```
Run the following command in your terminal to format your files.
```bash
npx prettier . --write
```
