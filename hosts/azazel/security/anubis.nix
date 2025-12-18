{
  config,
  ...
}:

{
  users = {
    users = {
      nginx = {
        extraGroups = [
          config.users.groups.anubis.name
        ];
      };
    };
  };
}
