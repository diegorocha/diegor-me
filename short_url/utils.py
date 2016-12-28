import string

_alphabet_base_62 = string.digits + string.letters


def is_base62(value):
    return len(set(value) - set(_alphabet_base_62)) == 0 and len(value) > 0


def base62_to_int(value):
    return base_to_int(value, _alphabet_base_62)


def base_to_int(value, alphabet=['0', '1']):
    n = 0
    base = len(alphabet)
    for i, l in enumerate(value[::-1]):
        if l in alphabet:
            n += alphabet.index(l) * base ** i
        else:
            raise Exception('%s not in alphabet' % l)
    return n
