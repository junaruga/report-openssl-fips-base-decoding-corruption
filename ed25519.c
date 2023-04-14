#include <stdlib.h>
#include <string.h>
#include <openssl/evp.h>
#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/bio.h>
#include <openssl/provider.h>

/* BEGIN COPY */
/* The following is extracted from https://github.com/junaruga/openssl/raw/41bc792df2cf54660264bd6fc6368044f2877e99/ext/openssl/ossl_pkey.c and modified to get rid of Ruby specific stuff */
# include <openssl/decoder.h>

void ossl_membio2str(BIO*);

EVP_PKEY *
ossl_pkey_read_generic(BIO *bio, char *pass)
{
    void *ppass = (void *)pass;
    OSSL_DECODER_CTX *dctx;
    EVP_PKEY *pkey = NULL;
    int pos = 0, pos2;

    dctx = OSSL_DECODER_CTX_new_for_pkey(&pkey, "DER", NULL, NULL, 0, NULL, NULL);
    if (!dctx)
        goto out;
    if (OSSL_DECODER_CTX_set_pem_password_cb(dctx, PEM_def_callback, ppass) != 1)
        goto out;

    /* First check DER */
    if (OSSL_DECODER_from_bio(dctx, bio) == 1)
        goto out;
    BIO_reset(bio);

    OSSL_DECODER_CTX_free(dctx);
    dctx = NULL;
    dctx = OSSL_DECODER_CTX_new_for_pkey(&pkey, "PEM", NULL, NULL,
                                         EVP_PKEY_KEYPAIR, NULL, NULL);
    if (!dctx)
        goto out;
    if (OSSL_DECODER_CTX_set_pem_password_cb(dctx, PEM_def_callback, ppass) != 1)
        goto out;
    while (1) {
        if (OSSL_DECODER_from_bio(dctx, bio) == 1)
            goto out;
        if (BIO_eof(bio))
            break;
        pos2 = BIO_tell(bio);
        if (pos2 < 0 || pos2 <= pos)
            break;
        ERR_clear_error();       /* Maybe print? */
        pos = pos2;
    }

    BIO_reset(bio);
    OSSL_DECODER_CTX_free(dctx);
    dctx = NULL;
    dctx = OSSL_DECODER_CTX_new_for_pkey(&pkey, "PEM", NULL, NULL, 0, NULL, NULL);
    if (!dctx)
        goto out;
    if (OSSL_DECODER_CTX_set_pem_password_cb(dctx, PEM_def_callback, ppass) != 1)
        goto out;
    while (1) {
        if (OSSL_DECODER_from_bio(dctx, bio) == 1)
            goto out;
        if (BIO_eof(bio))
            break;
        pos2 = BIO_tell(bio);
        if (pos2 < 0 || pos2 <= pos)
            break;
        ERR_clear_error();       /* Maybe print? */
        pos = pos2;
    }

  out:
    OSSL_DECODER_CTX_free(dctx);
    return pkey;
}

/*
 *  call-seq:
 *     OpenSSL::PKey.read(string [, pwd ]) -> PKey
 *     OpenSSL::PKey.read(io [, pwd ]) -> PKey
 *
 * Reads a DER or PEM encoded string from _string_ or _io_ and returns an
 * instance of the appropriate PKey class.
 *
 * === Parameters
 * * _string_ is a DER- or PEM-encoded string containing an arbitrary private
 *   or public key.
 * * _io_ is an instance of IO containing a DER- or PEM-encoded
 *   arbitrary private or public key.
 * * _pwd_ is an optional password in case _string_ or _io_ is an encrypted
 *   PEM resource.
 */
static EVP_PKEY *
ossl_pkey_new_from_data(char *data, char *pass)
{
    EVP_PKEY *pkey;
    BIO *bio;

    bio = BIO_new_mem_buf(data, strlen(data));
    if (!bio) {
        fprintf(stderr, "[DEBUG] BIO_new_mem_buf() failed\n");
        return NULL;
    }
    pkey = ossl_pkey_read_generic(bio, pass);
    BIO_free(bio);
    if (!pkey)
        fprintf(stderr, "Could not parse PKey\n");
    return pkey;
}

/* END COPY */

static int print_provider(OSSL_PROVIDER *prov, void *unused)
{
    printf("  %s\n", OSSL_PROVIDER_get0_name(prov));
    return 1;
}

void
ossl_pkey_export_spki(EVP_PKEY *pkey, int to_der)
{
    BIO *bio;

    bio = BIO_new(BIO_s_mem());
    if (!bio)
        fprintf(stderr, "BIO_new\n");
    if (to_der) {
        if (!i2d_PUBKEY_bio(bio, pkey)) {
            BIO_free(bio);
            fprintf(stderr, "i2d_PUBKEY_bio\n");
        }
    }
    else {
        if (!PEM_write_bio_PUBKEY(bio, pkey)) {
            BIO_free(bio);
            fprintf(stderr, "PEM_write_bio_PUBKEY\n");
        }
    }
    ossl_membio2str(bio);
}

void
ossl_membio2str(BIO *bio)
{
    BUF_MEM *buf;

    BIO_get_mem_ptr(bio, &buf);
    /*
    ret = ossl_str_new(buf->data, buf->length, &state);
    BIO_free(bio);
    if (state)
        rb_jump_tag(state);
     */

    printf("[DEBUG] ossl_membio2str buf->data:\n%s\n", buf->data);
}

int main(int argc, char *argv[])
{
    static char data[1024 * 1024];
    EVP_PKEY *pkey;

    printf("[DEBUG] Loaded providers:\n");
    OSSL_PROVIDER_do_all(NULL, &print_provider, NULL);

    /* Slurp */
    FILE *f;
    size_t data_size;

    if ((f = fopen(argv[1], "r")) == NULL
        || (data_size = fread(data, 1, sizeof(data), f)) == 0) {
        if (f)
            fclose(f);
        fprintf(stderr, "[DEBUG] Could not read PKey\n");
    } else {
        fclose(f);
        data[data_size] = '\0';
        pkey = ossl_pkey_new_from_data(data, "");
        if (pkey) {
            printf("[DEBUG] Got a pkey! %p\n", (void *)pkey);
            printf("[DEBUG] It's held by the provider %s\n",
                   OSSL_PROVIDER_get0_name(EVP_PKEY_get0_provider(pkey)));
        }

        ossl_pkey_export_spki(pkey, 0);

        EVP_PKEY_free(pkey);
    }

    /* ERR_print_errors_fp(stderr); */
}
