import { WebPlugin } from '@capacitor/core';
import type { MediaAlbumCreate, MediaAlbumResponse, MediaFetchOptions, MediaPlugin, MediaResponse, MediaSaveOptions, PhotoResponse } from './definitions';
export declare class MediaWeb extends WebPlugin implements MediaPlugin {
    getMedias(options?: MediaFetchOptions): Promise<MediaResponse>;
    getAlbums(): Promise<MediaAlbumResponse>;
    savePhoto(options?: MediaSaveOptions): Promise<PhotoResponse>;
    saveVideo(options?: MediaSaveOptions): Promise<PhotoResponse>;
    saveGif(options?: MediaSaveOptions): Promise<PhotoResponse>;
    saveDocument(options?: MediaSaveOptions): Promise<PhotoResponse>;
    createAlbum(options: MediaAlbumCreate): Promise<void>;
}
