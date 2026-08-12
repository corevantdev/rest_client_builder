class Address {} extension AddressExt on Address { static Address fromJson(String s) => Address(); } void main() { print(Address.fromJson("123")); }
