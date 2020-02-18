(self: super: {
  vikunja-api = super.callPackage ./vikunja-api {};

  vikunja-frontend = super.callPackage ./vikunja-frontend {};
})
