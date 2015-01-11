kafka Cookbook
==============
This cookbook does setup of a kafka broker

Requirements
------------
This cookbook requires runit cookbook and java.

Usage
-----
#### kafka::default

e.g.
Just include `kafka` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[kafka]"
  ]
}
```
License and Authors
-------------------
Authors: maxc0d3r
