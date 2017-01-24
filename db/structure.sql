--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: active_admin_comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE active_admin_comments (
    id integer NOT NULL,
    namespace character varying DEFAULT 'f'::character varying NOT NULL,
    resource_id integer NOT NULL,
    resource_type character varying NOT NULL,
    author_id integer NOT NULL,
    author_type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    body text
);


--
-- Name: active_admin_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE active_admin_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_admin_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE active_admin_comments_id_seq OWNED BY active_admin_comments.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE customers (
    id integer NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE customers_id_seq OWNED BY customers.id;


--
-- Name: data_files; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE data_files (
    id integer NOT NULL,
    name character varying NOT NULL,
    metadata jsonb DEFAULT '"{}"'::jsonb NOT NULL,
    customer_id integer NOT NULL,
    upload_file_name character varying NOT NULL,
    upload_content_type character varying NOT NULL,
    upload_file_size integer NOT NULL,
    upload_updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: data_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE data_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE data_files_id_seq OWNED BY data_files.id;


--
-- Name: data_quality_reports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE data_quality_reports (
    id integer NOT NULL,
    workflow_id integer NOT NULL,
    name character varying NOT NULL,
    sql_params jsonb DEFAULT '"{}"'::jsonb NOT NULL,
    sql text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    transcompiled_source text,
    transcompiled_source_language character varying,
    copied_from_data_quality_report_id integer
);


--
-- Name: data_quality_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE data_quality_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_quality_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE data_quality_reports_id_seq OWNED BY data_quality_reports.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    workflow_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notifications_id_seq OWNED BY notifications.id;


--
-- Name: runs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE runs (
    id integer NOT NULL,
    workflow_id integer NOT NULL,
    creator_id integer NOT NULL,
    execution_plan jsonb NOT NULL,
    status character varying DEFAULT 'unstarted'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE runs_id_seq OWNED BY runs.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: transform_dependencies; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE transform_dependencies (
    id integer NOT NULL,
    prerequisite_transform_id integer NOT NULL,
    postrequisite_transform_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: transform_dependencies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE transform_dependencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transform_dependencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE transform_dependencies_id_seq OWNED BY transform_dependencies.id;


--
-- Name: transform_run_log; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE transform_run_log (
    id integer NOT NULL,
    run_id integer NOT NULL,
    step_id integer NOT NULL,
    step_type character varying NOT NULL,
    step_name character varying NOT NULL,
    completed_successfully boolean DEFAULT false NOT NULL,
    errors jsonb DEFAULT '"{}"'::jsonb NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: transform_run_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE transform_run_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transform_run_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE transform_run_log_id_seq OWNED BY transform_run_log.id;


--
-- Name: transform_validations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE transform_validations (
    id integer NOT NULL,
    transform_id integer NOT NULL,
    validation_id integer NOT NULL,
    sql_params jsonb DEFAULT '"{}"'::jsonb NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: transform_validations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE transform_validations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transform_validations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE transform_validations_id_seq OWNED BY transform_validations.id;


--
-- Name: transforms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE transforms (
    id integer NOT NULL,
    name character varying NOT NULL,
    runner character varying NOT NULL,
    workflow_id integer NOT NULL,
    sql_params jsonb DEFAULT '"{}"'::jsonb NOT NULL,
    sql text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    transcompiled_source text,
    transcompiled_source_language character varying,
    data_file_id integer,
    copied_from_transform_id integer
);


--
-- Name: transforms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE transforms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transforms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE transforms_id_seq OWNED BY transforms.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: validations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE validations (
    id integer NOT NULL,
    name character varying NOT NULL,
    immutable boolean DEFAULT false NOT NULL,
    sql text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    transcompiled_source text,
    transcompiled_source_language character varying
);


--
-- Name: validations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE validations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: validations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE validations_id_seq OWNED BY validations.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE versions (
    id integer NOT NULL,
    item_type character varying NOT NULL,
    item_id integer NOT NULL,
    event character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    user_id integer,
    whodunnit character varying,
    object jsonb,
    object_changes jsonb
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE versions_id_seq OWNED BY versions.id;


--
-- Name: workflows; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE workflows (
    id integer NOT NULL,
    name character varying NOT NULL,
    schema_base_name character varying NOT NULL,
    dbms character varying DEFAULT 'postgres'::character varying NOT NULL,
    customer_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    copied_from_workflow_id integer
);


--
-- Name: workflows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workflows_id_seq OWNED BY workflows.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY active_admin_comments ALTER COLUMN id SET DEFAULT nextval('active_admin_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY customers ALTER COLUMN id SET DEFAULT nextval('customers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY data_files ALTER COLUMN id SET DEFAULT nextval('data_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY data_quality_reports ALTER COLUMN id SET DEFAULT nextval('data_quality_reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications ALTER COLUMN id SET DEFAULT nextval('notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY runs ALTER COLUMN id SET DEFAULT nextval('runs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY transform_dependencies ALTER COLUMN id SET DEFAULT nextval('transform_dependencies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY transform_run_log ALTER COLUMN id SET DEFAULT nextval('transform_run_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY transform_validations ALTER COLUMN id SET DEFAULT nextval('transform_validations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY transforms ALTER COLUMN id SET DEFAULT nextval('transforms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY validations ALTER COLUMN id SET DEFAULT nextval('validations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions ALTER COLUMN id SET DEFAULT nextval('versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflows ALTER COLUMN id SET DEFAULT nextval('workflows_id_seq'::regclass);


--
-- Name: active_admin_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY active_admin_comments
    ADD CONSTRAINT active_admin_comments_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: data_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY data_files
    ADD CONSTRAINT data_files_pkey PRIMARY KEY (id);


--
-- Name: data_quality_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY data_quality_reports
    ADD CONSTRAINT data_quality_reports_pkey PRIMARY KEY (id);


--
-- Name: notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY runs
    ADD CONSTRAINT runs_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: transform_dependencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY transform_dependencies
    ADD CONSTRAINT transform_dependencies_pkey PRIMARY KEY (id);


--
-- Name: transform_run_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY transform_run_log
    ADD CONSTRAINT transform_run_log_pkey PRIMARY KEY (id);


--
-- Name: transform_validations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY transform_validations
    ADD CONSTRAINT transform_validations_pkey PRIMARY KEY (id);


--
-- Name: transforms_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY transforms
    ADD CONSTRAINT transforms_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: validations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY validations
    ADD CONSTRAINT validations_pkey PRIMARY KEY (id);


--
-- Name: versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: workflows_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY workflows
    ADD CONSTRAINT workflows_pkey PRIMARY KEY (id);


--
-- Name: idx_data_quality_reports_on_copied_from_data_quality_report_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_data_quality_reports_on_copied_from_data_quality_report_id ON data_quality_reports USING btree (copied_from_data_quality_report_id);


--
-- Name: index_active_admin_comments_on_author_id_and_author_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_active_admin_comments_on_author_id_and_author_type ON active_admin_comments USING btree (author_id, author_type);


--
-- Name: index_active_admin_comments_on_namespace; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_active_admin_comments_on_namespace ON active_admin_comments USING btree (namespace);


--
-- Name: index_customers_on_lowercase_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_customers_on_lowercase_name ON customers USING btree (lower((name)::text));


--
-- Name: index_customers_on_lowercase_slug; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_customers_on_lowercase_slug ON customers USING btree (lower((slug)::text));


--
-- Name: index_data_files_on_customer_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_data_files_on_customer_id ON data_files USING btree (customer_id);


--
-- Name: index_data_files_on_lowercase_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_data_files_on_lowercase_name ON data_files USING btree (lower((name)::text));


--
-- Name: index_data_quality_reports_on_lowercase_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_data_quality_reports_on_lowercase_name ON data_quality_reports USING btree (lower((name)::text));


--
-- Name: index_data_quality_reports_on_workflow_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_data_quality_reports_on_workflow_id ON data_quality_reports USING btree (workflow_id);


--
-- Name: index_notifications_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_notifications_on_user_id ON notifications USING btree (user_id);


--
-- Name: index_notifications_on_workflow_id_and_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_notifications_on_workflow_id_and_user_id ON notifications USING btree (workflow_id, user_id);


--
-- Name: index_runs_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_runs_on_creator_id ON runs USING btree (creator_id);


--
-- Name: index_runs_on_workflow_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_runs_on_workflow_id ON runs USING btree (workflow_id);


--
-- Name: index_transform_dependencies_on_prerequisite_transform_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transform_dependencies_on_prerequisite_transform_id ON transform_dependencies USING btree (prerequisite_transform_id);


--
-- Name: index_transform_dependencies_on_unique_transform_ids; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_transform_dependencies_on_unique_transform_ids ON transform_dependencies USING btree (postrequisite_transform_id, prerequisite_transform_id);


--
-- Name: index_transform_run_log_on_run_id_and_step_id_and_step_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_transform_run_log_on_run_id_and_step_id_and_step_type ON transform_run_log USING btree (run_id, step_id, step_type);


--
-- Name: index_transform_run_log_on_step_id_and_step_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transform_run_log_on_step_id_and_step_type ON transform_run_log USING btree (step_id, step_type);


--
-- Name: index_transform_validations_on_validation_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transform_validations_on_validation_id ON transform_validations USING btree (validation_id);


--
-- Name: index_transforms_on_copied_from_transform_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transforms_on_copied_from_transform_id ON transforms USING btree (copied_from_transform_id);


--
-- Name: index_transforms_on_data_file_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transforms_on_data_file_id ON transforms USING btree (data_file_id);


--
-- Name: index_transforms_on_lowercase_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_transforms_on_lowercase_name ON transforms USING btree (lower((name)::text));


--
-- Name: index_transforms_on_workflow_id_and_data_file_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_transforms_on_workflow_id_and_data_file_id ON transforms USING btree (workflow_id, data_file_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_validations_on_lowercase_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_validations_on_lowercase_name ON validations USING btree (lower((name)::text));


--
-- Name: index_versions_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_versions_on_created_at ON versions USING btree (created_at);


--
-- Name: index_versions_on_item_id_and_item_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_versions_on_item_id_and_item_type ON versions USING btree (item_id, item_type);


--
-- Name: index_versions_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_versions_on_user_id ON versions USING btree (user_id);


--
-- Name: index_workflows_on_copied_from_workflow_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workflows_on_copied_from_workflow_id ON workflows USING btree (copied_from_workflow_id);


--
-- Name: index_workflows_on_customer_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workflows_on_customer_id ON workflows USING btree (customer_id);


--
-- Name: index_workflows_on_lowercase_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_workflows_on_lowercase_name ON workflows USING btree (lower((name)::text));


--
-- Name: index_workflows_on_lowercase_schema_base_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_workflows_on_lowercase_schema_base_name ON workflows USING btree (lower((schema_base_name)::text));


--
-- Name: resource_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX resource_created_at ON active_admin_comments USING btree (resource_id, resource_type, created_at);


--
-- Name: fk_rails_215d6c0d1f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY transforms
    ADD CONSTRAINT fk_rails_215d6c0d1f FOREIGN KEY (copied_from_transform_id) REFERENCES transforms(id);


--
-- Name: fk_rails_31def9802a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflows
    ADD CONSTRAINT fk_rails_31def9802a FOREIGN KEY (copied_from_workflow_id) REFERENCES workflows(id);


--
-- Name: fk_rails_3f13522448; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY transforms
    ADD CONSTRAINT fk_rails_3f13522448 FOREIGN KEY (data_file_id) REFERENCES data_files(id);


--
-- Name: fk_rails_404232665a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY runs
    ADD CONSTRAINT fk_rails_404232665a FOREIGN KEY (workflow_id) REFERENCES workflows(id);


--
-- Name: fk_rails_4ec34a7d94; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY data_quality_reports
    ADD CONSTRAINT fk_rails_4ec34a7d94 FOREIGN KEY (copied_from_data_quality_report_id) REFERENCES data_quality_reports(id);


--
-- Name: fk_rails_5040d0e343; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflows
    ADD CONSTRAINT fk_rails_5040d0e343 FOREIGN KEY (customer_id) REFERENCES customers(id);


--
-- Name: fk_rails_56d6267752; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT fk_rails_56d6267752 FOREIGN KEY (workflow_id) REFERENCES workflows(id);


--
-- Name: fk_rails_666d7f2016; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY transforms
    ADD CONSTRAINT fk_rails_666d7f2016 FOREIGN KEY (workflow_id) REFERENCES workflows(id);


--
-- Name: fk_rails_689b9ffda6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY transform_dependencies
    ADD CONSTRAINT fk_rails_689b9ffda6 FOREIGN KEY (postrequisite_transform_id) REFERENCES transforms(id);


--
-- Name: fk_rails_6daa254f0d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY transform_run_log
    ADD CONSTRAINT fk_rails_6daa254f0d FOREIGN KEY (run_id) REFERENCES runs(id);


--
-- Name: fk_rails_8a742645db; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY transform_validations
    ADD CONSTRAINT fk_rails_8a742645db FOREIGN KEY (validation_id) REFERENCES validations(id);


--
-- Name: fk_rails_914f13c63b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT fk_rails_914f13c63b FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_98b72d517e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY data_files
    ADD CONSTRAINT fk_rails_98b72d517e FOREIGN KEY (customer_id) REFERENCES customers(id);


--
-- Name: fk_rails_a46b8f09db; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY runs
    ADD CONSTRAINT fk_rails_a46b8f09db FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: fk_rails_ae1a0fa57c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY data_quality_reports
    ADD CONSTRAINT fk_rails_ae1a0fa57c FOREIGN KEY (workflow_id) REFERENCES workflows(id);


--
-- Name: fk_rails_b080fb4855; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT fk_rails_b080fb4855 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_e09f268cd9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY transform_validations
    ADD CONSTRAINT fk_rails_e09f268cd9 FOREIGN KEY (transform_id) REFERENCES transforms(id);


--
-- Name: fk_rails_fc2f9284ca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY transform_dependencies
    ADD CONSTRAINT fk_rails_fc2f9284ca FOREIGN KEY (prerequisite_transform_id) REFERENCES transforms(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES
('20170112005400'),
('20170112022558'),
('20170113013703'),
('20170113235922');


