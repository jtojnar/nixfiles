final: prev: {
  youtube-dl = ((prev.youtube-dl.override {
    ffmpeg = prev.ffmpeg.overrideAttrs (attrs: {
      patches = attrs.patches or [] ++ [
        (prev.writeText "ffmpeg-http-increase-request-buffer.patch" ''
          --- a/libavformat/http.c
          +++ b/libavformat/http.c
          @@ -46,7 +46,7 @@
           /* The IO buffer size is unrelated to the max URL size in itself, but needs
            * to be large enough to fit the full request headers (including long
            * path names). */
          -#define BUFFER_SIZE   (MAX_URL_SIZE + HTTP_HEADERS_SIZE)
          +#define BUFFER_SIZE   (MAX_URL_SIZE + HTTP_HEADERS_SIZE * 10)
           #define MAX_REDIRECTS 8
           #define HTTP_SINGLE   1
           #define HTTP_MUTLI    2
        '')
      ];
    });
  }).overrideAttrs (attrs: {
    patches = attrs.patches or [] ++ [
      # Add Microsoft Stream support
      # https://github.com/ytdl-org/youtube-dl/pull/24649
      (prev.fetchpatch {
        url = "https://github.com/ytdl-org/youtube-dl/commit/05698ebf9b7264ada5b1a3a29ca5b508f87262b9.patch";
        sha256 = "wKE7vPlcxnYAHh9J70wizEQW0Cmw5i3U56YTDaQHMh4=";
      })
      (prev.fetchpatch {
        url = "https://github.com/ytdl-org/youtube-dl/commit/5416301787f048579f30fda25dc234dc3d52f722.patch";
        sha256 = "VBpsZFzyu6aD3xEQibH+7rdlkRz6sNYPqBSzI7e03tM=";
      })
      (prev.fetchpatch {
        url = "https://github.com/ytdl-org/youtube-dl/commit/292be92987999fe5bcd28dd782bb41e0a08cec4f.patch";
        sha256 = "R0PjK98DTNAR8WIIpYvvvcAMoF/o4Ic5D1zJLygHFSA=";
      })
      (prev.fetchpatch {
        url = "https://github.com/ytdl-org/youtube-dl/commit/67db51cdfe08bcaf9cf2500851ba2d0f04163757.patch";
        sha256 = "3Xe9qDL44KPtBNWccpKpw5PmuoL92ANbC/8zI4fp25U=";
      })
      (prev.fetchpatch {
        url = "https://github.com/ytdl-org/youtube-dl/commit/5e7738a0df9bd6c00fea256b546c05e590efac26.patch";
        sha256 = "D5oYOCbIY9j319DYUSz0yQFzvGoxOJfVFysABKC4ylE=";
      })
    ];
  }));
}
