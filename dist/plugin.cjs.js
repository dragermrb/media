'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

var core = require('@capacitor/core');

const Media = core.registerPlugin('Media', {
    web: () => Promise.resolve().then(function () { return web; }).then(m => new m.MediaWeb()),
});

class MediaWeb extends core.WebPlugin {
    getMedias(options) {
        console.log('getMedias', options);
        throw this.unimplemented('Not implemented on web.');
    }
    getAlbums() {
        throw this.unimplemented('Not implemented on web.');
    }
    savePhoto(options) {
        console.log('savePhoto', options);
        throw this.unimplemented('Not implemented on web.');
    }
    saveVideo(options) {
        console.log('saveVideo', options);
        throw this.unimplemented('Not implemented on web.');
    }
    saveGif(options) {
        console.log('saveGif', options);
        throw this.unimplemented('Not implemented on web.');
    }
    saveDocument(options) {
        console.log('saveDocument', options);
        throw this.unimplemented('Not implemented on web.');
    }
    createAlbum(options) {
        console.log('createAlbum', options);
        throw this.unimplemented('Not implemented on web.');
    }
}

var web = /*#__PURE__*/Object.freeze({
    __proto__: null,
    MediaWeb: MediaWeb
});

exports.Media = Media;
//# sourceMappingURL=plugin.cjs.js.map
