# static-assets

The static-assets volume contains the binary and text assets that do not belong in the xqerl database.
These assets may include images, icons, stylesheets, fonts, scripts etc.

```
└── src
    ├── assets
    │   ├── casts
    │   │   └── xqerl-up-and-flying.cast
    │   ├── images
    │   │   ├── favicon.ico
    │   │   └── logo.png
    │   ├── scripts
    │   │   └── prism.js
    │   └── styles
    │       └── sakura.css
```

When running, the 'xq' container mounts the static-assets volume.
Invoking the Make target  `make` will put these assets in the `src/assets` directory into the static assets volume.

Any web request URI *path* that starts with `/assets` will serve files from the static assets volume

## Preprocessing Assets
 
Asset source file may be **preprocessed** before they are stored into the `static-assets` volume.
The preproccesing stages, aka *asset pipeline*, prior to storing the asset may consist of one stage feeding into another.

A preprocessing asset pipeline stage depends on the end result required for the asset type.
Images may need some form of file size optimisation, stylesheet may be gzipped etc

The preprocessing code is handled in `inc/assets.mk`, 
which you may need to modify to suite your use cases.
You you prefer a bundler or have a favourite minifier, linter etc

The important thing is to get your assets into the static-assets volume in the form you require, 
not the process of getting there.

## Database Links To Binary Assets

TODO

