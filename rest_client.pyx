import logging
import platform
logger = logging.getLogger(__name__)
from cgi import parse_header
from mimetools import Message
from cStringIO import StringIO

from libc.stddef cimport size_t
from libc.stdlib cimport malloc, free, realloc
from libc.string cimport memcpy
from cpython cimport *
from curl cimport *

# {{{ callback
cdef size_t write_to_list(void *contents, size_t size, size_t nmemb, void *userp):
    cdef size_t realsize = size * nmemb
    raw_header = <list>userp
    val = PyString_FromString(<char *>contents)
    PyList_Append(raw_header, val)
    return realsize
# }}}

cdef class Response(object):
    cdef readonly long status_code
    cdef readonly bytes text
    cdef readonly bytes content_type
    cdef readonly list raw_header
    cdef readonly object headers
    cdef readonly bytes encoding
    cdef readonly bytes url
    cdef readonly bytes reason
    cdef readonly bool is_redirect
    cdef readonly bool ok

    def __cinit__(self, text, raw_header):
        self.text = text
        self.raw_header = raw_header
        # http://stackoverflow.com/questions/4685217/parse-raw-http-headers
        self.headers = Message(StringIO(''.join(raw_header[1:])))

    @property
    def content_length(self):
        return self.headers['content-length']

    def __dealloc__(self):
        pass

cpdef Response request(const char *method, const char *url):
    cdef char *version
    cdef CURLcode ret
    cdef long true = 1L
    version = curl_version()
    logger.debug("curl version: {0}".format(version))
    cdef CURL *curl = curl_easy_init()
    _user_agent = 'rest_client {}'.format(version)
    cdef const char *user_agent = _user_agent
    cdef const char *accept_encoding = 'gzip, deflate'
    cdef char *content_type
    cdef char *content_encoding
    cdef char *vary
    cdef char *server
    cdef char *connection
    cdef char *date
    cdef char *effective_url
    raw_header = []
    raw_body = []

    if curl != NULL:
        curl_easy_setopt(curl, CURLOPT_VERBOSE, &true)
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, &true)
        logger.debug("url: {0}".format(url))
        ret = curl_easy_setopt(curl, CURLOPT_URL, url)

        if method == <bytes>'POST':
            ret = curl_easy_setopt(curl, CURLOPT_POST, &true)
        elif method == <bytes>'PUT':
            ret = curl_easy_setopt(curl, CURLOPT_PUT, &true)
        else:
            ret = curl_easy_setopt(curl, CURLOPT_HTTPGET, &true)

        ret = curl_easy_setopt(curl, CURLOPT_USERAGENT, user_agent)
        ret = curl_easy_setopt(curl, CURLOPT_ACCEPT_ENCODING, accept_encoding)

        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, &write_to_list)
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, <void *>raw_body)

        curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, &write_to_list)
        curl_easy_setopt(curl, CURLOPT_HEADERDATA, <void *>raw_header)

        if ret != CURLE_OK:
            logger.error('curl: ({0}) {1}'.format(ret, curl_easy_strerror(ret)))
        logger.debug('curl_easy_perform')
        ret = curl_easy_perform(curl)
        if ret != CURLE_OK:
            logger.error('curl: ({0}) {1}'.format(ret, curl_easy_strerror(ret)))

        resp = Response(''.join(raw_body), raw_header)
        resp.reason = raw_header[0].rstrip('\r\n').split(' ')[-1]
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &resp.status_code)
        curl_easy_getinfo(curl, CURLINFO_CONTENT_TYPE, &content_type)
        resp.content_type = <bytes>content_type
        _, params = parse_header(resp.content_type)
        resp.encoding = params.get('charset', '')
        curl_easy_getinfo(curl, CURLINFO_EFFECTIVE_URL, &effective_url)
        resp.url = effective_url
        resp.is_redirect = effective_url == url

        curl_easy_cleanup(curl)
        return resp

cpdef Response get(const char *url):
    return request('GET', url)

# vim: set fdm=marker:
