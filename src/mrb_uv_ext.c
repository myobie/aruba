#include <mruby.h>
#include <mruby/data.h>
#include <mruby/string.h>
#include <mruby/variable.h>
#include <uv.h>

mrb_value
mrb_aruba_uv_work_initialize(mrb_state *mrb, mrb_value self)
{
  mrb_value work_proc, after_proc;
  /* mrb_uv_req_t *req; */

  mrb_get_args(mrb, "oo", &work_proc, &after_proc);

  if (mrb_type(work_proc) != MRB_TT_PROC || mrb_type(after_proc) != MRB_TT_PROC) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "requires 2 arguments, both procs");
  }

  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "finished"), mrb_false_value());
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "work_proc"), work_proc);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "after_proc"), after_proc);

  return self;
}

typedef struct mrb_instance_house {
  mrb_state *mrb;
  mrb_value instance;
} mrb_instance_house;

static void
mrb_uv_work_req_t_free(mrb_state *mrb, void *p)
{
  if (p) {
    uv_req_t *req = (uv_req_t *)p;
    if (req->type == UV_FS) {
      uv_fs_req_cleanup((uv_fs_t *)&req);
    }
    mrb_free(mrb, p);
  }
}

uv_req_t*
mrb_uv_work_req_t_alloc(mrb_state *mrb, mrb_value instance, uv_req_type t)
{
  mrb_instance_house *house;
  uv_req_t *req_t;

  mrb_assert(!mrb_nil_p(instance));

  req_t = (uv_req_t *)mrb_malloc(mrb, uv_req_size(t));

  house = (mrb_instance_house *)mrb_malloc(mrb, sizeof(mrb_instance_house));
  house->mrb = mrb;
  house->instance = instance;

  req_t->data = house;

  return req_t;
}

static void
mrb_uv_work_call_work(uv_work_t *req)
{
  mrb_instance_house *house = (mrb_instance_house *)req->data;
  mrb_state *mrb = house->mrb;
  mrb_value proc = mrb_iv_get(mrb, house->instance, mrb_intern_lit(mrb, "work_proc"));

  mrb_assert(mrb_type(proc) == MRB_TT_PROC);
  mrb_funcall(mrb, proc, "call", 0, NULL);
}

#define E_UV_ERROR mrb_class_get(mrb, "UVError")

void
mrb_uv_work_req_t_check_error(mrb_state *mrb, int err)
{
  mrb_value argv[2];

  if (err >= 0) {
    return;
  }

  mrb_assert(err < 0);
  argv[0] = mrb_str_new_cstr(mrb, uv_strerror(err));
  argv[1] = mrb_symbol_value(mrb_intern_cstr(mrb, uv_err_name(err)));
  mrb_exc_raise(mrb, mrb_obj_new(mrb, E_UV_ERROR, 2, argv));
}

static void
mrb_uv_work_call_after(uv_work_t *req, int err)
{
  mrb_instance_house *house = (mrb_instance_house *)req->data;
  mrb_state *mrb = house->mrb;
  mrb_value proc = mrb_iv_get(mrb, house->instance, mrb_intern_lit(mrb, "after_proc"));

  mrb_assert(mrb_type(proc) == MRB_TT_PROC);
  mrb_funcall(mrb, proc, "call", 0, NULL);

  mrb_uv_work_req_t_check_error(mrb, err);
  mrb_uv_work_req_t_free(mrb, req);
  mrb_free(mrb, house);
}

mrb_value
mrb_aruba_uv_work_call(mrb_state *mrb, mrb_value self)
{
  mrb_value proc_name, string_name, full_string_name, work_name, after_name, proc, result;
  mrb_sym proc_sym;

  mrb_get_args(mrb, "n", &proc_sym);

  proc_name = mrb_symbol_value(proc_sym);

  work_name = mrb_check_intern_cstr(mrb, "work");
  after_name = mrb_check_intern_cstr(mrb, "after");

  if (!mrb_eql(mrb, proc_name, work_name) && !mrb_eql(mrb, proc_name, after_name)) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "argument to #work must be :work or :after");
  }

  string_name = mrb_sym2str(mrb, mrb_symbol(proc_name));
  full_string_name = mrb_str_plus(mrb, string_name, mrb_str_new_lit(mrb, "_proc"));

  proc = mrb_iv_get(mrb, self, mrb_intern_str(mrb, full_string_name));

  result = mrb_funcall(mrb, proc, "call", 0, NULL);

  return result;
}

mrb_value
mrb_aruba_uv_work_finished_eh(mrb_state *mrb, mrb_value self)
{
  mrb_value result;
  result = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "finished"));
  return result;
}

mrb_value
mrb_aruba_uv_work_work(mrb_state *mrb, mrb_value self)
{
  uv_req_t* req;

  req = mrb_uv_work_req_t_alloc(mrb, self, UV_WORK);
  mrb_uv_work_req_t_check_error(mrb, uv_queue_work(uv_default_loop(), (uv_work_t *)req, mrb_uv_work_call_work, mrb_uv_work_call_after));

  return self;
}

void
mrb_aruba_gem_init(mrb_state* mrb)
{
  int ai = mrb_gc_arena_save(mrb);

  struct RClass* _class_uv;
  struct RClass* _class_uv_work;

  _class_uv = mrb_define_module(mrb, "UV");
  _class_uv_work = mrb_define_class_under(mrb, _class_uv, "Work", mrb->object_class);

  mrb_define_method(mrb, _class_uv_work, "initialize", mrb_aruba_uv_work_initialize, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, _class_uv_work, "finished?", mrb_aruba_uv_work_finished_eh, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_work, "call", mrb_aruba_uv_work_call, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_work, "work", mrb_aruba_uv_work_work, MRB_ARGS_NONE());

  mrb_gc_arena_restore(mrb, ai);
}

void
mrb_aruba_gem_final(mrb_state* mrb)
{
}
