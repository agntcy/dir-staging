# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/gavinbunney/kubectl" {
  version     = "1.19.0"
  constraints = "~> 1.19"
  hashes = [
    "h1:aQUITuBBjv8WJ+WGI0bOZXXYi5s09pMEyyJmlFnuUbE=",
    "zh:1dec8766336ac5b00b3d8f62e3fff6390f5f60699c9299920fc9861a76f00c71",
    "zh:43f101b56b58d7fead6a511728b4e09f7c41dc2e3963f59cf1c146c4767c6cb7",
    "zh:4c4fbaa44f60e722f25cc05ee11dfaec282893c5c0ffa27bc88c382dbfbaa35c",
    "zh:51dd23238b7b677b8a1abbfcc7deec53ffa5ec79e58e3b54d6be334d3d01bc0e",
    "zh:5afc2ebc75b9d708730dbabdc8f94dd559d7f2fc5a31c5101358bd8d016916ba",
    "zh:6be6e72d4663776390a82a37e34f7359f726d0120df622f4a2b46619338a168e",
    "zh:72642d5fcf1e3febb6e5d4ae7b592bb9ff3cb220af041dbda893588e4bf30c0c",
    "zh:9b12af85486a96aedd8d7984b0ff811a4b42e3d88dad1a3fb4c0b580d04fa425",
    "zh:a1da03e3239867b35812ee031a1060fed6e8d8e458e2eaca48b5dd51b35f56f7",
    "zh:b98b6a6728fe277fcd133bdfa7237bd733eae233f09653523f14460f608f8ba2",
    "zh:bb8b071d0437f4767695c6158a3cb70df9f52e377c67019971d888b99147511f",
    "zh:dc89ce4b63bfef708ec29c17e85ad0232a1794336dc54dd88c3ba0b77e764f71",
    "zh:dd7dd18f1f8218c6cd19592288fde32dccc743cde05b9feeb2883f37c2ff4b4e",
    "zh:ec4bd5ab3872dedb39fe528319b4bba609306e12ee90971495f109e142d66310",
    "zh:f610ead42f724c82f5463e0e71fa735a11ffb6101880665d93f48b4a67b9ad82",
  ]
}

provider "registry.terraform.io/hashicorp/helm" {
  version     = "2.17.0"
  constraints = "~> 2.17"
  hashes = [
    "h1:UXXOgqsqALJFmxAQ3BQcSLJxNcn7qgzEH/P3FEqNkCU=",
    "zh:06fb4e9932f0afc1904d2279e6e99353c2ddac0d765305ce90519af410706bd4",
    "zh:104eccfc781fc868da3c7fec4385ad14ed183eb985c96331a1a937ac79c2d1a7",
    "zh:129345c82359837bb3f0070ce4891ec232697052f7d5ccf61d43d818912cf5f3",
    "zh:3956187ec239f4045975b35e8c30741f701aa494c386aaa04ebabffe7749f81c",
    "zh:66a9686d92a6b3ec43de3ca3fde60ef3d89fb76259ed3313ca4eb9bb8c13b7dd",
    "zh:88644260090aa621e7e8083585c468c8dd5e09a3c01a432fb05da5c4623af940",
    "zh:a248f650d174a883b32c5b94f9e725f4057e623b00f171936dcdcc840fad0b3e",
    "zh:aa498c1f1ab93be5c8fbf6d48af51dc6ef0f10b2ea88d67bcb9f02d1d80d3930",
    "zh:bf01e0f2ec2468c53596e027d376532a2d30feb72b0b5b810334d043109ae32f",
    "zh:c46fa84cc8388e5ca87eb575a534ebcf68819c5a5724142998b487cb11246654",
    "zh:d0c0f15ffc115c0965cbfe5c81f18c2e114113e7a1e6829f6bfd879ce5744fbb",
    "zh:f569b65999264a9416862bca5cd2a6177d94ccb0424f3a4ef424428912b9cb3c",
  ]
}

provider "registry.terraform.io/hashicorp/kubernetes" {
  version     = "2.38.0"
  constraints = "~> 2.38"
  hashes = [
    "h1:PrqdwvK/d9ZW1G35lUc5nkMyHa3/9+JOnbs66IJHNNw=",
    "zh:0af928d776eb269b192dc0ea0f8a3f0f5ec117224cd644bdacdc682300f84ba0",
    "zh:1be998e67206f7cfc4ffe77c01a09ac91ce725de0abaec9030b22c0a832af44f",
    "zh:326803fe5946023687d603f6f1bab24de7af3d426b01d20e51d4e6fbe4e7ec1b",
    "zh:4a99ec8d91193af961de1abb1f824be73df07489301d62e6141a656b3ebfff12",
    "zh:5136e51765d6a0b9e4dbcc3b38821e9736bd2136cf15e9aac11668f22db117d2",
    "zh:63fab47349852d7802fb032e4f2b6a101ee1ce34b62557a9ad0f0f0f5b6ecfdc",
    "zh:924fb0257e2d03e03e2bfe9c7b99aa73c195b1f19412ca09960001bee3c50d15",
    "zh:b63a0be5e233f8f6727c56bed3b61eb9456ca7a8bb29539fba0837f1badf1396",
    "zh:d39861aa21077f1bc899bc53e7233262e530ba8a3a2d737449b100daeb303e4d",
    "zh:de0805e10ebe4c83ce3b728a67f6b0f9d18be32b25146aa89116634df5145ad4",
    "zh:f569b65999264a9416862bca5cd2a6177d94ccb0424f3a4ef424428912b9cb3c",
    "zh:faf23e45f0090eef8ba28a8aac7ec5d4fdf11a36c40a8d286304567d71c1e7db",
  ]
}

provider "registry.terraform.io/hashicorp/random" {
  version     = "3.9.0"
  constraints = "~> 3.6"
  hashes = [
    "h1:zK+EG72uHuIWwy5Me6q2IxG/r859YA3AhqJRwUK2lOg=",
    "zh:161ad0bd9a75768c82f53fb6e7172a9d8be2d4889b012645a34795031aaf1bf1",
    "zh:19dc9a5b17729725ccfc4f45b0500af0ee5bc6b6b160c7adb8f2bf617d2c80ea",
    "zh:269eda8fe42daa7974d5a34d166c3ba9defe80cde86c01e4dadcfdf2e1f05e5f",
    "zh:373f7c65566f8f2cc7f45d698654feb9d988996957e1266a69ca00c52d6d16d0",
    "zh:5599d16804c41c83009ec621b6d6b6f74e102f5827678a4750f8809055546b61",
    "zh:583be0440469a22bff70dcfa56593b01566860b29607437264adb51060cf46fc",
    "zh:5f211d8ec3f2e1f414870d9584bfe26e6995560ef81c748f8447a48164767398",
    "zh:78d5eefdd9e494defcb3c68d282b8f96630502cac21d1ea161f53cfe9bb483b3",
    "zh:7b547fd16216761ef86efc3ed516ac5ac0c5c42b7c7eb24a08cef2d93f69ed5e",
    "zh:7e7c0679daf2a382151d05068c8c3f0dae6b7b7dccf818827b73dd08638df2ef",
    "zh:8089dec888a8038b9b4fb23b3df7e1057293dbc5b60b42cc47ff690d69d4b61b",
    "zh:c51f15a031edfd6f23ce8ced3446ca7f8d8d647e2499890d7d5d10d5016d7257",
    "zh:c94784f005708890dc6895afd53636ec00ec1e430b15d41e5aebfb1d4b39bd04",
  ]
}

provider "registry.terraform.io/loafoe/htpasswd" {
  version     = "1.6.0"
  constraints = "~> 1.2"
  hashes = [
    "h1:wg1XKvfXEQduRklptPo/WroTh3fYmpb7sIx8ZO/ymog=",
    "zh:0050ca190d3f905668ec6c2bcaef44b251357cb1a1fa46c72059d7ee9a3dd62c",
    "zh:014cd65e585d9f38e55250d9f52a933cd84aada3e763f27fe85e59244d8260fa",
    "zh:03c4b24da1dd85b2c33f5649dd8c6f509e76ab2e8c023f01576354c74cda3c56",
    "zh:1e2eeb9f7e88335503ed469218002ba6a477fd538ab0b23ac4d02d834eaecdc9",
    "zh:386b173176ff2d04a038413edd4842bec0f4ccede63eb90e4603ec369c033363",
    "zh:65bce4aa385a20b9294d50b7e17b5feff4d447e29dbc8e8a3e8823fc10b7de48",
    "zh:b534794eeb7909890fca59d9a08dec1168e65d867f12f3187fdbbc8c710a0af8",
    "zh:cb399ec66e2490e10ddeca0c5678b265c8826f7b0cdfb7259d2de85371e41358",
    "zh:cfb1a4c703ca28ca13f79313ec5cd70ed9f310e9f7e109a955fb112a78d0ba01",
    "zh:cff1c25002fc6d2e76e126f5bed678d9ad4902d08730011ce1e1f4fe37cc3526",
    "zh:e85e8ca2cb1a4f512199c16907a08ff9753a067ab109cb8137466069281808aa",
    "zh:eb2e20a2ee9430c2cd8240eaab6d2c61737c67478518970c6e3d9d332b6a73cc",
  ]
}
