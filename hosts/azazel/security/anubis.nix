{
  config,
  ...
}:

{
  users = {
    users = {
      caddy = {
        extraGroups = [
          config.users.groups.anubis.name
        ];
      };
    };
  };
}
