HiveMind
========

_Distributed File Storage Using JavaScript Botnets_

Additional documentation, demo, and presentation are available at [http://www.seantmalone.com/projects](http://www.seantmalone.com/projects).

Abstract
--------
Some data is too sensitive or volatile to store on systems you own.  What if we could store it somewhere else without compromising the security or availability of the data, while leveraging intended functionality to do so?  This software creates a distributed file store built on top of a JavaScript botnet.  This type of data storage offers redundancy and encryption, and allows you to store a virtually unlimited amount of data in any type of file.   They can seize your server -- but the data’s not there!

Origin
------
This project grew out of musings about the potential uses and abuses of HTML5 features.  There's so much more power here than initially meets the eye, and more and more new features are being added to browsers with the end user having little to no awareness.  That results in some interesting software architectures in which the browser is actually a key component.

Uses
----
There are a number of different uses for this technology:

- Creating an opt-in distributed file storage among a group of peers
- Inviting users of a website to participate in the distributed file store, in exchange for membership on the site or other perks
- Hiding data that cannot fall into the wrong hands

Disclaimer
----------
This is a research project, not production software. I am not responsible if you lose critical data through the use of this software. Use at your own risk.

Also, I am not a lawyer. Nothing in this software, documentation, or associated presentation constitutes legal advice, and I do not recommend using these concepts or this software for any illegal purposes. 

Setup & Operation
-----------------
This is unsupported, non-production software.  That being said, feel free to open an issue if something isn't working, and I'll try to help.

1. In order to build the botnet, you need to direct traffic to http://[server]/node.html.  I find that it works well to include an Iframe with this URL as the source.  It is not sufficient to include the JavaScript directly into a page on another domain, since this creates problems with cross-origin requests.  You can, however, include the Iframe in a page on a different domain, since this creates a separate security domain inside the Iframe.

    Note: It's possible to inject this Iframe into sites using an anonymous proxy that modifies the traffic passing through the proxy.  The code for this proxy is in [nginx.conf] (https://github.com/seantmalone/HiveMind/blob/master/doc/nginx.conf) and [proxysite.conf] (https://github.com/seantmalone/HiveMind/blob/master/doc/proxysite.conf).

2. On the server side, set up the application and ActiveRecord database like any other Rails application.  I used capistrano to deploy, and you can use [deploy.rb] (https://github.com/seantmalone/HiveMind/blob/master/config/deploy.rb) as an example.

3. You will also need to have Redis installed and running on the server.  Redis is used for storing the block directory.

4. Next, start up the WebSocket listener.  This is a standalone server, and separate from the main Nginx Rails server.  It can be started with the following command, run from the application root directory:

    ```
    rake websocket_rails:start_server
    ```

5. Finally, you'll need to start a Rails runner to handle the ongoing block monitoring and replication.  This is done with the following command:

    ```
    rails runner -e production 'HiveFile.replicate' &
    ```
    
Have fun!  The code is, admittedly, very poorly documented.  That being said, I do my best to write readable code, so it shouldn't be too hard to figure out what's going on.  One hint on this: if it looks like a particular item (such as requesting a block) is being repeated in two different ways, it's likely that one way is for the WebSocket nodes, and one is for the AJAX nodes.   
    
