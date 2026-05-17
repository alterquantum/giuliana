--
-- PostgreSQL database dump
--

\restrict VF3ibMZ6UJkhLQ7jcLjvgzIwA8R8NjLikbzbdFaSiqnrTgl2qi8PaZ0cx4bCUqq

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: categorie_materiali; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.categorie_materiali (id, nome) FROM stdin;
019e313c-ba29-7586-9034-2b8e8c77ea38	Calcestruzzo e malte
019e313c-ba2a-7747-8a7c-4c41228c7248	Laterizi e blocchi
019e313c-ba2a-77d3-a713-c1de7758c698	Acciaio e ferro
019e313c-ba2a-77e6-ae45-c88947a4e62a	Legname
019e313c-ba2a-77f5-840f-6b923d278e2d	Impianti elettrici
019e313c-ba2a-7809-87cf-a8187fbd17f7	Impianti idraulici
019e313c-ba2a-7824-ac30-09243034e701	Isolanti
019e313c-ba2a-7834-a413-882c9830ff05	Finiture e pavimenti
019e313c-ba2a-784b-bca7-49f2dc4e246a	Ferramenta
019e313c-ba2a-785b-83b2-01e6979065c4	Altro
\.


--
-- Data for Name: qualifiche; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.qualifiche (id, nome, descrizione) FROM stdin;
019e313c-ba27-7fe4-9ea4-cbafa3d44812	Muratore	\N
019e313c-ba29-7045-976c-a99b7b01e8f3	Elettricista	\N
019e313c-ba29-708f-a7db-e525ad275356	Idraulico	\N
019e313c-ba29-70a5-9547-addf6868087b	Carpentiere	\N
019e313c-ba29-70b8-814e-39d9bf78b6ad	Gruista	\N
019e313c-ba29-70c8-b8a9-de2a31c7c601	Saldatore	\N
019e313c-ba29-70d9-b0ad-db31cd145f4b	Piastrellista	\N
019e313c-ba29-71b9-91fd-604983d7bcaf	Pittore	\N
019e313c-ba29-71c9-8c4e-51f1c936e1e4	Ferraiolo	\N
019e313c-ba29-71d9-91fe-1ed382b78d59	Decoratore	\N
\.


--
-- Data for Name: ruoli; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ruoli (id, nome, descrizione) FROM stdin;
019e313c-ba26-7a52-98cc-37c6cc07bfe0	admin	Accesso completo a tutto il gestionale
019e313c-ba27-7ba8-8a37-99afbce46192	capo_cantiere	Gestione operativa cantieri assegnati, registrazione presenze
019e313c-ba27-7c3c-9e58-4f4fd5ad1224	operaio	Visualizzazione proprie presenze e documenti personali
\.


--
-- Data for Name: tipi_documento; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tipi_documento (id, nome) FROM stdin;
019e313c-ba2a-7c9d-b1e0-db0b7b881bcb	Contratto
019e313c-ba2b-7f6c-8973-780072c841b8	Permesso di costruire
019e313c-ba2c-7001-a83e-50b902160a43	DURC
019e313c-ba2c-7016-9c38-b58ad912eb89	DVR
019e313c-ba2c-7024-acaf-d4df2fd1ae0a	Piano di sicurezza
019e313c-ba2c-7037-a1ea-58de8fdd45ed	Collaudo
019e313c-ba2c-7049-8c88-3688c884dc04	Fattura
019e313c-ba2c-705a-9fba-d8ec4b9c9832	DDT
019e313c-ba2c-7068-aebf-2b11feba32b6	Certificazione materiale
019e313c-ba2c-707d-91c9-a97408517431	Altro
\.


--
-- PostgreSQL database dump complete
--

\unrestrict VF3ibMZ6UJkhLQ7jcLjvgzIwA8R8NjLikbzbdFaSiqnrTgl2qi8PaZ0cx4bCUqq


-- Admin utente
INSERT INTO utenti (id_ruolo, username, email, password_hash, nome, cognome, attivo)
SELECT r.id, 'giuliana.arch', 'giuliana.arch@gmail.com',
       '$2y$10$85KV50LL.TKiX93Brzagwegzrytz7sg41TDMI.2z/RZ3jOyeywOKi',
       'Giuliana', 'Arch', true
FROM ruoli r WHERE r.nome = 'admin'
ON CONFLICT DO NOTHING;
