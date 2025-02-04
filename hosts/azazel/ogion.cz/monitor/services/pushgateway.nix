{
  config,
  ...
}:

{
  services.prometheus = {
    pushgateway = {
      enable = true;
      # 9091 taken by Authelia
      web.listen-address = ":9092";
    };

    scrapeConfigs = [
      {
        job_name = "pushgateway";
        scrape_interval = "10s";
        static_configs = [
          {
            targets = [
              "localhost${config.services.prometheus.pushgateway.web.listen-address}"
            ];
          }
        ];
      }
    ];
  };
}
