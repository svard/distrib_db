# DistribDb

Distributed fault tolerent key value store in Elixir.

## Usage

Fire up two or more iex sessions on different hosts like so

    $ iex --name distrib_db@192.168.0.1 -S mix
    $ iex --name distrib_db@192.168.0.2 -S mix

And then connect the nodes together.

    # On 192.168.0.1
    iex> Node.connect :"distrib_db@192.168.0.2"

It is then possible to connect to any of the nodes via telnet and run some commands.

    $ telnet 192.168.0.1 4040
    telnet> CREATE store
    telnet> PUT store key 42
    telnet> GET store key
    # => 42

The CREATE command can also take a timout in seconds when to expire the database

    # Creates a database that delete itself after one day
    telnet> CREATE store 86400

All PUT requests will be replicated to every node in the cluster.

To add a new node to the cluster connect it to one of the existing cluster nodes and run the sync command

    iex> Node.connect :"distrib_db@192.168.0.1"
    iex> DistribDb.Controller.sync

This will copy over all existing databases from one of the nodes in the cluster to the new node.
