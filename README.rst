使用 Cython 封装 curl 示例
=========================

安装依赖
````````

仅在 Ubuntu 上测试通过

.. sourcecode:: sh

    sudo apt-get install -y build-essential gdb python-dev python-virtualenv libcurl4-gnutls-dev
    pip install cython
    python setup.py build_ext --inplace

使用
````

.. sourcecode:: python

    >>> import rest_client
    >>> response = rest_client.get('http://ifconfig.me/all.json')
    * About to connect() to ifconfig.me port 80 (#0)
    *   Trying 153.121.72.212... * connected
    > GET /all.json HTTP/1.1
    User-Agent: rest_client libcurl/7.22.0 GnuTLS/2.12.14 zlib/1.2.3.4 libidn/1.23 librtmp/2.3
    Host: ifconfig.me
    Accept: */*
    Accept-Encoding: gzip, deflate

    < HTTP/1.1 200 OK
    < Date: Tue, 11 Nov 2014 08:55:39 GMT
    < Server: Apache
    < Vary: Accept-Encoding
    < Content-Encoding: gzip
    < Content-Length: 213
    < Connection: close
    < Content-Type: application/json
    < 
    * Closing connection #0
    >>> response.status_code
    200
    >>> response.text
    '{"connection":"","ip_addr":"xxx.xxx.xxx.xxx","lang":"","remote_host":"","user_agent":"rest_client libcurl/7.22.0 GnuTLS/2.12.14 zlib/1.2.3.4 libidn/1.23 librtmp/2.3","charset":"","port":"65522","via":"","forwarded":"","mime":"*/*","keep_alive":"","encoding":"gzip, deflate"}\n'
    >>> response.headers
    <mimetools.Message instance at 0x7ffff7ea4ef0>
    >>> response.headers.items()
    [('content-length', '213'), ('content-encoding', 'gzip'), ('vary', 'Accept-Encoding'), ('server', 'Apache'), ('connection', 'close'), ('date', 'Tue, 11 Nov 2014 08:55:39 GMT'), ('content-type', 'application/json')]
