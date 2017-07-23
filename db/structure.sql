SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

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
-- Name: data_quality_reports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE data_quality_reports (
    id integer NOT NULL,
    name character varying NOT NULL,
    sql text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    immutable boolean DEFAULT false
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
    created_at timestamp without time zone NOT NULL,
    workflow_configuration_id integer NOT NULL
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
-- Name: run_step_logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE run_step_logs (
    id integer NOT NULL,
    run_id integer NOT NULL,
    step_type character varying NOT NULL,
    step_index integer DEFAULT 0 NOT NULL,
    step_id integer DEFAULT 0 NOT NULL,
    successful boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    step_validation_failures jsonb,
    step_exceptions jsonb,
    step_result jsonb
);


--
-- Name: run_step_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE run_step_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: run_step_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE run_step_logs_id_seq OWNED BY run_step_logs.id;


--
-- Name: runs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE runs (
    id integer NOT NULL,
    creator_id integer NOT NULL,
    execution_plan jsonb NOT NULL,
    status character varying DEFAULT 'unstarted'::character varying NOT NULL,
    notification_status character varying DEFAULT 'unsent'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    schema_name character varying,
    workflow_configuration_id integer NOT NULL
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
-- Name: transform_validations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE transform_validations (
    id integer NOT NULL,
    transform_id integer NOT NULL,
    validation_id integer NOT NULL,
    params jsonb NOT NULL,
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
    runner character varying DEFAULT 'Sql'::character varying NOT NULL,
    workflow_id integer NOT NULL,
    sql text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    params jsonb,
    s3_file_name character varying
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
    updated_at timestamp without time zone NOT NULL
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
-- Name: workflow_configurations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE workflow_configurations (
    id bigint NOT NULL,
    workflow_id integer NOT NULL,
    s3_region_name character varying NOT NULL,
    s3_bucket_name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    customer_id integer,
    s3_file_path character varying
);


--
-- Name: workflow_configurations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflow_configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workflow_configurations_id_seq OWNED BY workflow_configurations.id;


--
-- Name: workflow_data_quality_reports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE workflow_data_quality_reports (
    id integer NOT NULL,
    workflow_id integer NOT NULL,
    data_quality_report_id integer NOT NULL,
    params jsonb NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: workflow_data_quality_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflow_data_quality_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_data_quality_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workflow_data_quality_reports_id_seq OWNED BY workflow_data_quality_reports.id;


--
-- Name: workflow_dependencies; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE workflow_dependencies (
    id integer NOT NULL,
    included_workflow_id integer NOT NULL,
    including_workflow_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: workflow_dependencies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflow_dependencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_dependencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workflow_dependencies_id_seq OWNED BY workflow_dependencies.id;


--
-- Name: workflows; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE workflows (
    id integer NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    default_copy_from_sql character varying,
    default_copy_from_s3_file_type character varying,
    default_copy_to_sql character varying,
    default_copy_to_s3_file_type character varying
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

ALTER TABLE ONLY data_quality_reports ALTER COLUMN id SET DEFAULT nextval('data_quality_reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications ALTER COLUMN id SET DEFAULT nextval('notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY run_step_logs ALTER COLUMN id SET DEFAULT nextval('run_step_logs_id_seq'::regclass);


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

ALTER TABLE ONLY workflow_configurations ALTER COLUMN id SET DEFAULT nextval('workflow_configurations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflow_data_quality_reports ALTER COLUMN id SET DEFAULT nextval('workflow_data_quality_reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflow_dependencies ALTER COLUMN id SET DEFAULT nextval('workflow_dependencies_id_seq'::regclass);


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
-- Name: run_step_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY run_step_logs
    ADD CONSTRAINT run_step_logs_pkey PRIMARY KEY (id);


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
-- Name: workflow_configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY workflow_configurations
    ADD CONSTRAINT workflow_configurations_pkey PRIMARY KEY (id);


--
-- Name: workflow_data_quality_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY workflow_data_quality_reports
    ADD CONSTRAINT workflow_data_quality_reports_pkey PRIMARY KEY (id);


--
-- Name: workflow_dependencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY workflow_dependencies
    ADD CONSTRAINT workflow_dependencies_pkey PRIMARY KEY (id);


--
-- Name: workflows_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY workflows
    ADD CONSTRAINT workflows_pkey PRIMARY KEY (id);


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
-- Name: index_data_quality_reports_on_lowercase_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_data_quality_reports_on_lowercase_name ON data_quality_reports USING btree (lower((name)::text));


--
-- Name: index_notifications_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_notifications_on_user_id ON notifications USING btree (user_id);


--
-- Name: index_notifications_on_workflow_configuration_id_and_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_notifications_on_workflow_configuration_id_and_user_id ON notifications USING btree (workflow_configuration_id, user_id);


--
-- Name: index_run_step_logs_on_run_id_and_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_run_step_logs_on_run_id_and_created_at ON run_step_logs USING btree (run_id, created_at);


--
-- Name: index_runs_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_runs_on_creator_id ON runs USING btree (creator_id);


--
-- Name: index_runs_on_workflow_configuration_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_runs_on_workflow_configuration_id ON runs USING btree (workflow_configuration_id);


--
-- Name: index_transform_dependencies_on_prerequisite_transform_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transform_dependencies_on_prerequisite_transform_id ON transform_dependencies USING btree (prerequisite_transform_id);


--
-- Name: index_transform_dependencies_on_unique_transform_ids; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_transform_dependencies_on_unique_transform_ids ON transform_dependencies USING btree (postrequisite_transform_id, prerequisite_transform_id);


--
-- Name: index_transform_validations_on_transform_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transform_validations_on_transform_id ON transform_validations USING btree (transform_id);


--
-- Name: index_transform_validations_on_validation_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_transform_validations_on_validation_id ON transform_validations USING btree (validation_id);


--
-- Name: index_transforms_on_lowercase_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_transforms_on_lowercase_name ON transforms USING btree (lower((name)::text));


--
-- Name: index_unique_workflow_configurations_on_workflow_customer; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_unique_workflow_configurations_on_workflow_customer ON workflow_configurations USING btree (workflow_id, customer_id);


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
-- Name: index_workflow_configurations_on_customer_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workflow_configurations_on_customer_id ON workflow_configurations USING btree (customer_id);


--
-- Name: index_workflow_data_quality_reports_on_data_quality_report_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workflow_data_quality_reports_on_data_quality_report_id ON workflow_data_quality_reports USING btree (data_quality_report_id);


--
-- Name: index_workflow_data_quality_reports_on_workflow_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workflow_data_quality_reports_on_workflow_id ON workflow_data_quality_reports USING btree (workflow_id);


--
-- Name: index_workflow_dependencies_on_including_workflow_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workflow_dependencies_on_including_workflow_id ON workflow_dependencies USING btree (including_workflow_id);


--
-- Name: index_workflow_depenencies_on_independent_id_dependent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_workflow_depenencies_on_independent_id_dependent_id ON workflow_dependencies USING btree (included_workflow_id, including_workflow_id);


--
-- Name: index_workflows_on_lowercase_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_workflows_on_lowercase_name ON workflows USING btree (lower((name)::text));


--
-- Name: index_workflows_on_lowercase_slug; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_workflows_on_lowercase_slug ON workflows USING btree (lower((slug)::text));


--
-- Name: resource_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX resource_created_at ON active_admin_comments USING btree (resource_id, resource_type, created_at);


--
-- Name: fk_rails_005a70e28c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflow_configurations
    ADD CONSTRAINT fk_rails_005a70e28c FOREIGN KEY (customer_id) REFERENCES customers(id);


--
-- Name: fk_rails_316d9533d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflow_configurations
    ADD CONSTRAINT fk_rails_316d9533d3 FOREIGN KEY (workflow_id) REFERENCES workflows(id);


--
-- Name: fk_rails_36b8cfa612; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY runs
    ADD CONSTRAINT fk_rails_36b8cfa612 FOREIGN KEY (workflow_configuration_id) REFERENCES workflow_configurations(id);


--
-- Name: fk_rails_466a60ec0d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT fk_rails_466a60ec0d FOREIGN KEY (workflow_configuration_id) REFERENCES workflow_configurations(id);


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
-- Name: fk_rails_83cf12c62e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflow_data_quality_reports
    ADD CONSTRAINT fk_rails_83cf12c62e FOREIGN KEY (data_quality_report_id) REFERENCES data_quality_reports(id);


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
-- Name: fk_rails_a46b8f09db; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY runs
    ADD CONSTRAINT fk_rails_a46b8f09db FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: fk_rails_b080fb4855; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT fk_rails_b080fb4855 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_bcd9d373c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY run_step_logs
    ADD CONSTRAINT fk_rails_bcd9d373c4 FOREIGN KEY (run_id) REFERENCES runs(id);


--
-- Name: fk_rails_db221ae1ec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflow_data_quality_reports
    ADD CONSTRAINT fk_rails_db221ae1ec FOREIGN KEY (workflow_id) REFERENCES workflows(id);


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

SET search_path TO public,shared_extensions;

INSERT INTO "schema_migrations" (version) VALUES
('20170112005400'),
('20170112022558'),
('20170113013703'),
('20170113235922'),
('20170217203644'),
('20170221232223'),
('20170303002731'),
('20170305232008'),
('20170403215347'),
('20170502012231'),
('20170504001059'),
('20170509204400'),
('20170510010559'),
('20170517030342');


